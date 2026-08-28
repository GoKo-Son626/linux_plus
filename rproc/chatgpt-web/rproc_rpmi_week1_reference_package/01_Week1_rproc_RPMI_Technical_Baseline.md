# 第 1 周：Linux remoteproc 与 RPMI 技术事实基线

> 目标：这不是“从零到精通”的长教程，而是本周所有解释、代码、测试的**事实底座**。  
> Linux release baseline：`v7.2`  
> Current-source snapshot：`torvalds/linux@1b78070aaef63512688aebfbc82365ef9d6660f1`  
> RPMI normative baseline：`riscv-non-isa/riscv-rpmi@v1.0`

---

# 1. 先建立唯一正确的总模型

## 1.1 一张图看清 remoteproc / virtio / rpmsg

```text
                 Linux Application Processor
┌───────────────────────────────────────────────────────────┐
│ userspace                                                │
│   /sys/class/remoteproc/remoteprocX/*                    │
│                  │                                        │
│                  ▼                                        │
│        Linux remoteproc core                              │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ rproc object / state / firmware / resource table   │  │
│  │ boot / shutdown / attach / crash recovery          │  │
│  └─────────────────────────────────────────────────────┘  │
│                  │ rproc_ops                              │
│                  ▼                                        │
│        SoC-specific remoteproc driver                     │
│     reset / power / mailbox / address translation         │
│                  │                                        │
└──────────────────┼────────────────────────────────────────┘
                   │
                   ▼
             Remote Processor
           (e.g. STM32MP1 M4)
                   │
        firmware contains ELF + optional resource table
                   │
        ┌──────────┴──────────┐
        │ RSC_CARVEOUT / ...  │
        │ RSC_VDEV            │
        └──────────┬──────────┘
                   ▼
                virtio
                   ▼
             virtqueue/vring
                   ▼
                 rpmsg
          channel / endpoint / payload
```

结论：

- `remoteproc` 管“**这个远端核怎么准备、装固件、启动、停机、恢复**”。
- `virtio/rpmsg` 管“**启动以后两边怎么通过 vring 做消息通信**”。
- 二者关系很紧，但不是一个东西。

---

# 2. RPMI 是另一条轴

```text
Application Processor (AP)
        │
        │ RPMI request / response / notification
        ▼
RPMI client
        │
        ▼
RPMI messaging protocol
        │
        ▼
RPMI transport
        │
        ├── direct platform transport
        │
        └── SBI MPXY virtualized path
        ▼
Platform Microcontroller (PuC)
        │
        └── clock / system MSI / power / system management / ...
```

RPMI v1.0 的定位是：

> AP 与 platform microcontroller 之间的**平台管理与控制接口**。

它定义的是：

- transport 抽象；
- message format；
- service group；
- client/context；
- runtime discovery。

所以：

```text
remoteproc = Linux remote CPU lifecycle framework
RPMI       = RISC-V platform management protocol/interface
rpmsg      = virtio-based IPC messaging bus
SBI MPXY   = 可代理/虚拟化消息协议的 SBI extension
```

不要问“remoteproc 和 RPMI 哪个替代哪个”，这本身就是错误问题。

---

# 3. Linux 当前基线

2026-08-28：

```text
official mainline release: v7.2
stable:                    v7.2.1
```

本材料检查前沿 API 时固定：

```text
torvalds/linux
commit 1b78070aaef63512688aebfbc82365ef9d6660f1
```

以后源码变化时，Codex 重新核对，不得把本材料中的函数成员永久视为固定 ABI。

---

# 4. remoteproc 源码地图

第 1 周只需要把这些文件建立索引：

```text
include/linux/remoteproc.h
include/linux/rsc_table.h

drivers/remoteproc/
├── remoteproc_core.c
├── remoteproc_elf_loader.c
├── remoteproc_virtio.c
├── remoteproc_sysfs.c
├── remoteproc_internal.h
└── stm32_rproc.c

Documentation/staging/
├── remoteproc.rst
└── rpmsg.rst

Documentation/devicetree/bindings/remoteproc/
└── st,stm32-rproc.yaml
```

优先级：

```text
真实 .c/.h
  >
当前 DT YAML schema
  >
Documentation/staging/*.rst
  >
旧博客
```

`Documentation/staging/remoteproc.rst` 很适合建立概念，但它的简化 API 示例不代表当前 `struct rproc_ops` 的完整成员列表。

---

# 5. `struct rproc`：框架核心对象

当前 `include/linux/remoteproc.h` 中，`struct rproc` 至少要理解这些字段的角色：

```text
name / firmware
    remote processor 名称、固件名

priv
    平台驱动私有数据

ops
    平台相关操作

state
    remote processor 状态

power
    “需要该 rproc 保持 powered”的引用计数

lock
    串行化关键状态操作的 mutex

carveouts / mappings
    remote processor 相关内存资源

rvdevs
    remote virtio devices

notifyids
    vring/notification ID 管理

table_ptr / cached_table / clean_table / table_sz
    resource table 的不同阶段/副本

bootaddr
    固件入口地址

crash_handler / crash_cnt / recovery_disabled
    crash/recovery

dump_segments / dump_conf
    coredump
```

关键认识：

```text
struct rproc
不是“驱动私有结构体”
而是 remoteproc core 对一个物理 remote processor 的统一软件模型。
```

平台私有内容放在：

```c
rproc->priv
```

---

# 6. 当前 `struct rproc_ops`

在当前固定 master commit 中：

```c
struct rproc_ops {
    int (*prepare)(struct rproc *rproc);
    int (*unprepare)(struct rproc *rproc);
    int (*start)(struct rproc *rproc);
    int (*stop)(struct rproc *rproc);
    int (*attach)(struct rproc *rproc);
    int (*detach)(struct rproc *rproc);
    void (*kick)(struct rproc *rproc, int vqid);
    void *(*da_to_va)(struct rproc *rproc, u64 da,
                      size_t len, bool *is_iomem);
    int (*parse_fw)(struct rproc *rproc,
                    const struct firmware *fw);
    int (*handle_rsc)(struct rproc *rproc, u32 rsc_type,
                      void *rsc, int offset, int avail);
    struct resource_table *(*find_loaded_rsc_table)(...);
    struct resource_table *(*get_loaded_rsc_table)(...);
    int (*load)(struct rproc *rproc,
                const struct firmware *fw);
    int (*sanity_check)(struct rproc *rproc,
                        const struct firmware *fw);
    u64 (*get_boot_addr)(struct rproc *rproc,
                         const struct firmware *fw);
    unsigned long (*panic)(struct rproc *rproc);
    void (*coredump)(struct rproc *rproc);
};
```

不要死背全部。

第 1 周只需要按职责分组：

```text
平台生命周期：
  prepare / unprepare
  start / stop
  attach / detach

IPC：
  kick

地址：
  da_to_va

固件：
  parse_fw
  load
  sanity_check
  get_boot_addr
  find/get_loaded_rsc_table

扩展：
  handle_rsc
  panic
  coredump
```

---

# 7. `rproc_alloc()` 与 `rproc_add()` 到底做什么

平台 remoteproc driver 的典型 probe 主线是：

```text
probe()
  ↓
devm_rproc_alloc() / rproc_alloc()
  ↓
填写/解析平台资源
  ↓
devm_rproc_add() / rproc_add()
```

不要误解：

```text
rproc_alloc()
  ≠ 启动 remote CPU

rproc_add()
  ≠ “直接同步执行 ->start()”
```

`rproc_add()` 是把该 rproc 注册进框架；auto-boot、firmware discovery 等后续行为再依据配置发生。

---

# 8. 最重要：当前 `rproc_boot()` 真正调用链

第 1 周必须能脱离文档画出这条链。

## 8.1 第一层

当前源码：

```text
rproc_boot(rproc)
  │
  ├─ validate rproc
  ├─ mutex_lock_interruptible(&rproc->lock)
  ├─ check rproc->deleting
  │
  ├─ atomic_inc_return(&rproc->power)
  │    └─ > 1:
  │         已有用户保持其运行
  │         不重复执行真实启动
  │
  ├─ state == RPROC_DETACHED ?
  │    ├─ yes → rproc_attach()
  │    └─ no
  │        ├─ request_firmware()
  │        ├─ rproc_fw_boot()
  │        └─ release_firmware()
  │
  ├─ error → power--
  └─ mutex_unlock()
```

这里有三个容易错的点：

### A. `power` 不是 `struct device` 的普通对象引用计数

它代表 remote processor 被多少用户要求保持 powered。

### B. `rproc_boot()` 不一定“加载固件再 boot”

如果状态是：

```text
RPROC_DETACHED
```

说明 remote processor 可能由别的实体已经启动，Linux 走 attach 路线。

### C. 平台 `->start()` 远在更深层

不是：

```text
rproc_boot()
  -> ops->start()
```

而是还有 firmware/resource/memory 等大量框架工作。

---

# 9. `rproc_fw_boot()`：框架真正完成了哪些准备

当前源码路径可压缩成：

```text
rproc_fw_boot(rproc, fw)
  │
  ├─ rproc_fw_sanity_check()
  ├─ rproc_enable_iommu()
  ├─ rproc_prepare_device()
  │
  ├─ rproc_get_boot_addr()
  │     └─ rproc->bootaddr
  │
  ├─ rproc_parse_fw()
  │     └─ resource table / coredump information ...
  │
  ├─ reset max_notifyid / nb_vdev
  │
  ├─ rproc_handle_resources(...)
  ├─ rproc_alloc_registered_carveouts()
  │
  └─ rproc_start(rproc, fw)
```

这就是理解 remoteproc 的主骨架：

```text
固件合法
→ 平台准备
→ 解析 ELF/资源
→ 分配/映射资源
→ load
→ 真正启动硬件
```

---

# 10. `rproc_start()`：什么时候真的进入平台 `->start()`

当前：

```text
rproc_start(rproc, fw)
  │
  ├─ rproc_load_segments()
  │     └─ 把 ELF program segments 放到 remote 可访问内存
  │
  ├─ 找 loaded resource table
  ├─ 把已由 host 更新的 cached resource table
  │  同步到 remote device memory
  │
  ├─ rproc_prepare_subdevices()
  │
  ├─ rproc->ops->start(rproc)
  │     └─ 这里才真正由平台驱动放开 remote CPU
  │
  ├─ rproc_start_subdevices()
  │
  └─ state = RPROC_RUNNING
```

一句话：

```text
remoteproc core 把“通用准备”做好，
平台 ->start() 只承担无法通用化的硬件启动动作。
```

这正是 Linux framework 的价值。

---

# 11. shutdown 路径

```text
rproc_shutdown()
  ↓
__rproc_shutdown()
  │
  ├─ lock
  ├─ validate state
  ├─ power--
  │   └─ 仍 > 0：不真正关闭
  │
  ├─ rproc_stop()
  │    ├─ stop subdevices
  │    ├─ reset resource table state
  │    ├─ rproc->ops->stop()
  │    ├─ unprepare subdevices
  │    └─ state = RPROC_OFFLINE
  │
  ├─ rproc_resource_cleanup()
  ├─ rproc_unprepare_device()
  ├─ rproc_disable_iommu()
  ├─ free cached resource table
  └─ unlock
```

要和 boot 对称地理解，不要只学启动。

---

# 12. crash 与 recovery

核心状态：

```c
enum rproc_state {
    RPROC_OFFLINE,
    RPROC_SUSPENDED,
    RPROC_RUNNING,
    RPROC_CRASHED,
    RPROC_ATTACHED,
    RPROC_DETACHED,
    RPROC_LAST,
};
```

平台驱动检测到 watchdog / fatal / MMU fault 等情况后，可报告：

```c
rproc_report_crash(rproc, type);
```

框架进入 crash/recovery 流程。

当前恢复大方向：

```text
CRASHED
  ↓
rproc_trigger_recovery()
  │
  ├─ attach-on-recovery feature ?
  │    └─ detach / attach recovery
  │
  └─ normal boot recovery
       ├─ rproc_stop(..., crashed=true)
       ├─ coredump
       ├─ request_firmware
       └─ rproc_start
```

第 1 周只掌握框架，不深入 coredump 格式。

---

# 13. ELF 在 remoteproc 里处于什么位置

不要把 remoteproc 理解成“一个 ELF loader”。

它实际上协调：

```text
firmware request
    ↓
ELF sanity check
    ↓
ELF entry point
    ↓
resource table
    ↓
program headers / segments
    ↓
DA/PA/VA 地址关系
    ↓
平台 reset/power/start
```

典型平台可以直接复用通用 ELF helper：

```text
rproc_elf_sanity_check
rproc_elf_get_boot_addr
rproc_elf_load_segments
rproc_elf_find_loaded_rsc_table
```

STM32 当前主线就是一个很好的例子。

---

# 14. 三个地址必须分清：DA / PA / VA

这是 remoteproc 学习最常见坑。

## Device Address (`DA`)

remote processor 看到/使用的地址。

例如：

```text
remote M4 固件认为某段 SRAM 在 0x10000000
```

这是 remote core 的视角。

## Physical / Bus Address (`PA` / bus address)

AP/Linux SoC 总线侧实际物理地址。

DA 和 PA：

```text
可能相等
也可能不相等
```

## Kernel Virtual Address (`VA`)

Linux CPU 真正访问该区域时映射后的内核虚拟地址。

关系：

```text
Remote firmware uses DA
         ↕ translation
SoC physical/bus address
         ↕ ioremap / DMA / kernel mapping
Linux VA
```

当前 remoteproc 提供：

```c
rproc_da_to_va(...)
```

平台也可以实现：

```c
ops->da_to_va
```

STM32 驱动还存在自己的 PA→DA 映射逻辑，因为其 `dma-ranges` 描述了 AP 与 M4 的地址视图关系。

---

# 15. Resource Table：它解决什么问题

资源表不是 Device Tree。

### Device Tree

主要由 Linux/boot firmware 使用，描述平台硬件：

```text
remoteproc device
reset
mailbox
reserved memory
syscon
interrupt
...
```

### Firmware Resource Table

通常嵌在 remote firmware 中，由 remoteproc 解析，用于表达该 firmware 需要/公布的资源。

结构概念：

```c
struct resource_table {
    u32 ver;
    u32 num;
    u32 reserved[2];
    u32 offset[];
};
```

每个 entry 先有：

```c
struct fw_rsc_hdr {
    u32 type;
    u8 data[];
};
```

当前通用 resource types：

```text
RSC_CARVEOUT = 0
RSC_DEVMEM   = 1
RSC_TRACE    = 2
RSC_VDEV     = 3
```

vendor range 另外保留。

---

# 16. Resource Table 的四个核心资源

## `RSC_CARVEOUT`

remote firmware 需要一块连续内存。

框架可能负责：

```text
分配
记录
地址映射
把最终地址写回 resource table
```

## `RSC_DEVMEM`

remote processor 需要访问某个设备内存区域，常涉及 IOMMU mapping。

## `RSC_TRACE`

remote firmware 公布 trace buffer，host 可以读取日志。

## `RSC_VDEV`

remote firmware 公布一个 virtio device。

这就是：

```text
Resource Table
    ↓ RSC_VDEV
virtio device
    ↓
vring / virtqueue
    ↓
例如 rpmsg virtio
```

---

# 17. Resource Table 为什么会有 cached / loaded 等不同版本

host 在 boot 前可能必须修改 resource table：

例如：

```text
firmware 原始 RSC_VDEV
    ↓
Linux 分配 vring
    ↓
写入最终地址 / notify ID
    ↓
remote processor 必须看到修改后的结果
```

所以 current core 中存在：

```text
cached_table
table_ptr
clean_table
```

不要机械记名字。

理解本质：

```text
“固件原始描述”
    +
“host 资源分配后的实际结果”
    +
“remote CPU 当前实际看到的 table”
```

在 boot/attach/detach/recovery 不同路径中要保持一致。

---

# 18. virtio / vring / rpmsg 的最小模型

第 1 周只掌握这层关系：

```text
RSC_VDEV
  ↓
remoteproc creates remote virtio device
  ↓
virtio driver
  ↓
virtqueue
  ↓
vring
  ↓
共享内存 descriptors + buffers
  ↓
kick / interrupt notification
  ↓
rpmsg message
```

### `kick`

在 `rproc_ops` 中：

```c
void (*kick)(struct rproc *rproc, int vqid);
```

含义不是“发送整个 rpmsg 数据”。

数据通常已经写入共享的 vring/buffer。

`kick` 是：

```text
告诉 remote CPU：
“某个 virtqueue 里有新工作，去看。”
```

具体通知机制是平台相关：

```text
mailbox
IPI
doorbell
interrupt register
...
```

---

# 19. STM32MP157 为什么是第 1 阶段最佳样板

当前主线：

```text
drivers/remoteproc/stm32_rproc.c
```

匹配：

```c
compatible = "st,stm32mp1-m4"
```

这里正好把 remoteproc 通用层与真实硬件层接起来。

---

# 20. STM32 当前 `rproc_ops`

当前：

```text
.prepare                 = stm32_rproc_prepare
.start                   = stm32_rproc_start
.stop                    = stm32_rproc_stop
.attach                  = stm32_rproc_attach
.detach                  = stm32_rproc_detach
.kick                    = stm32_rproc_kick

.load                    = rproc_elf_load_segments
.parse_fw                = stm32_rproc_parse_fw
.find_loaded_rsc_table   = rproc_elf_find_loaded_rsc_table
.get_loaded_rsc_table    = stm32_rproc_get_loaded_rsc_table
.sanity_check            = rproc_elf_sanity_check
.get_boot_addr           = rproc_elf_get_boot_addr
```

这组映射非常适合学习：

```text
通用 ELF 工作 → 直接复用 remoteproc core helper
硬件 reset/mailbox/memory → STM32 自己实现
```

这就是驱动抽象边界。

---

# 21. STM32 probe 路径

当前源码可压缩成：

```text
stm32_rproc_probe()
  │
  ├─ configure DMA mask
  ├─ parse optional firmware-name
  │
  ├─ devm_rproc_alloc(...)
  │
  ├─ stm32_rproc_parse_dt(...)
  │    ├─ watchdog IRQ
  │    ├─ reset
  │    ├─ hold_boot
  │    ├─ syscon
  │    └─ auto_boot
  │
  ├─ stm32_rproc_of_memory_translations(...)
  │    └─ dma-ranges → DA/bus address translation
  │
  ├─ read M4 status
  │    └─ already running → RPROC_DETACHED
  │
  ├─ create workqueue
  ├─ stm32_rproc_request_mbox(...)
  │
  └─ rproc_add(rproc)
```

这已经是一个成熟 remoteproc platform driver 的标准阅读模板：

```text
1. 怎么描述硬件
2. 怎么取得 reset/power/mailbox/memory
3. 怎么构造 rproc
4. ops 怎么实现
5. 怎么交给 core
```

以后看 K1 vendor driver，也按这个模板拆。

---

# 22. STM32 `prepare()` 做什么

当前 `stm32_rproc_prepare()`：

```text
遍历 memory-region
  ↓
取得 reserved memory resource
  ↓
PA → DA
  ↓
对普通区域创建 rproc_mem_entry
  ↓
加入 carveout
  ↓
对 coredump 可加入 segment

vdev0buffer 特殊处理
  ↓
作为 reserved memory 用于 vdev buffer allocation
```

因此第 1 周一定要把以下概念连起来：

```text
DTS memory-region
    ↓
reserved-memory
    ↓
rproc_mem_entry
    ↓
carveout list
    ↓
resource table / ELF loading / rpmsg buffer
```

---

# 23. STM32 mailbox 与 vring

当前驱动定义了 4 类 mailbox 名：

```text
vq0
vq1
shutdown
detach
```

其中：

```text
vq0 / vq1
  ↔ virtqueue notification

shutdown
  → host 通知 remote 即将关闭

detach
  → host 通知 remote 停止 IPC
```

收到 vq mailbox 回调后，最终会触发类似：

```c
rproc_vq_interrupt(rproc, vq_id);
```

发送方向的 `stm32_rproc_kick()` 则通过 mailbox 通知 remote。

于是形成：

```text
shared vring contains data
             +
mailbox carries notification
```

这两个角色必须分清。

---

# 24. STM32 DT binding：本周真正要会看什么

当前 schema：

```text
Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml
```

核心：

```yaml
compatible:
  const: st,stm32mp1-m4

reg:
  # RETRAM / MCU SRAM ranges

resets:
  # MCU reset / optional hold_boot reset

memory-region:
  # firmware / carveout / vring / rpmsg buffer...

mboxes:
mbox-names:
  # rpmsg/virtio 使用时需要

firmware-name:
st,auto-boot:
```

hold boot 可以依据当前平台设计通过：

```text
SCMI reset
或
syscon
（旧 SMC 路线已 deprecated）
```

不要拿某篇旧教程固定的 DTS 属性列表替代当前 YAML schema。

---

# 25. remoteproc sysfs：用户空间到底能控制什么

当前：

```text
/sys/class/remoteproc/remoteprocX/
├── name
├── state
├── firmware
├── recovery
└── coredump
```

### `state`

读：

```text
offline
suspended
running
crashed
attached
detached
```

写支持：

```text
start
stop
detach
```

其中：

```text
echo start > state
```

最终进入：

```c
rproc_boot()
```

而不是 sysfs 自己实现启动逻辑。

---

## `firmware`

读：

```text
当前配置固件名
```

如果是 Linux attach 到外部已经启动的 remote：

```text
unknown
```

写入会调用：

```c
rproc_set_firmware()
```

---

## `recovery`

支持：

```text
enabled
disabled
recover
```

特别适合以后做 crash debug。

---

## `coredump`

当前支持：

```text
disabled
enabled
inline
```

第 1 周知道用途即可。

---

# 26. 本周板上观察命令

> 只有在目标板已经启用 remoteproc 驱动时执行。  
> 写操作前必须确认 firmware 和 remote processor 状态。

只读：

```bash
ls -l /sys/class/remoteproc/

for r in /sys/class/remoteproc/remoteproc*; do
    echo "=== $r ==="
    for f in name state firmware recovery coredump; do
        [ -r "$r/$f" ] && printf "%-10s: " "$f" && cat "$r/$f"
    done
done
```

如果确认 `remoteproc0` 是 M4 且固件已经准备：

```bash
R=/sys/class/remoteproc/remoteproc0

cat "$R/name"
cat "$R/state"
cat "$R/firmware"

# 仅在 offline 且确认固件存在时：
echo start | sudo tee "$R/state"
cat "$R/state"

# 实验结束：
echo stop | sudo tee "$R/state"
cat "$R/state"
```

如果失败：

```bash
dmesg -w
```

要记录：

```text
命令
→ sysfs 输入
→ rproc_boot 调用链
→ driver/core log
→ 最终 state
→ 失败 errno
```

---

# 27. RPMI v1.0：第 1 周只掌握 5 个抽象

Ratified v1.0 明确定义：

## 1. RPMI Transport

AP 与 PuC 交换 RPMI message 的传输机制。

transport instance 与 AP 的某个 RISC-V privilege level 关联。

## 2. RPMI Messaging Protocol

定义：

```text
message types
message format
request / response / notification 等交互规则
```

## 3. RPMI Service Groups

把 PuC 提供的平台管理服务按功能分组。

可包含：

```text
standard service groups
vendor service groups
```

## 4. RPMI Client

运行在 AP 上、能够发送/接收 RPMI message 的软件/driver。

## 5. RPMI Context

组合：

```text
1 transport instance
+ messaging layer
+ mandatory BASE service group
+ optional service groups
```

并与 privilege level 关联。

这 5 个是以后读 RPMI 全规范的坐标系。

---

# 28. RPMI 与 SBI MPXY 的关系

RPMI v1.0 允许 message-based communication 被：

```text
machine-mode firmware
或
hypervisor
```

通过 SBI MPXY 进行代理/虚拟化。

所以可能存在：

```text
Linux S-mode RPMI client
        ↓
Linux mailbox API
        ↓
SBI MPXY mailbox driver
        ↓
SBI ecall
        ↓
M-mode firmware
        ↓
real RPMI transport
        ↓
PuC
```

这不是说：

```text
RPMI == SBI
```

而是：

```text
RPMI message protocol
可以由 SBI MPXY 提供一个虚拟化/代理通道。
```

---

# 29. 当前 Linux 已经有 RPMI 实现，不只是规范

在本材料固定的 current master commit 中，已确认存在：

```text
include/linux/mailbox/riscv-rpmi-message.h

drivers/mailbox/riscv-sbi-mpxy-mbox.c
drivers/clk/clk-rpmi.c
drivers/irqchip/irq-riscv-rpmi-sysmsi.c

Documentation/devicetree/bindings/mailbox/
  riscv,rpmi-shmem-mbox.yaml
  riscv,sbi-mpxy-mbox.yaml

Documentation/devicetree/bindings/clock/
  riscv,rpmi-clock.yaml
  riscv,rpmi-mpxy-clock.yaml

Documentation/devicetree/bindings/interrupt-controller/
  riscv,rpmi-system-msi.yaml
  riscv,rpmi-mpxy-system-msi.yaml
```

注意：

- “有 direct shared-memory RPMI DT binding” **不等于** 本周已经确认主线里有一个同名 direct shared-memory mailbox controller `.c` 驱动；
- 当前明确验证到的是 SBI MPXY mailbox 实现，以及 Clock/System-MSI 客户端路径；
- 后续要以实际源码树继续确认 direct transport 的实现状态。

---

# 30. 当前 Linux RPMI message header

当前主线头文件：

```c
struct rpmi_message_header {
    __le16 servicegroup_id;
    u8 service_id;
    u8 flags;
    __le16 datalen;
    __le16 token;
};
```

然后：

```c
struct rpmi_message {
    struct rpmi_message_header header;
    u8 data[];
};
```

第 1 周先理解：

```text
servicegroup_id
    先确定是哪一组服务

service_id
    再确定组内哪个操作

flags
    message semantics

datalen
    payload length

token
    请求/响应关联等协议用途
```

具体 bit 语义以 RPMI v1.0 规范为准，不凭名称猜。

---

# 31. 当前 Linux 已实现的两个明显 client service group

`riscv-rpmi-message.h` 当前内核实现中可见：

```text
RPMI_SRVGRP_SYSTEM_MSI = 0x00002
RPMI_SRVGRP_CLOCK      = 0x00008
```

这只能证明：

```text
当前 Linux 这些 client 路径已实现/使用这些 service group
```

不能推出：

```text
RPMI v1.0 规范只有这两个 service group
```

“Linux 当前支持子集”和“规范完整定义”必须分开。

---

# 32. Linux `clk-rpmi.c` 给我们的真实例子

它把 Linux Clock Framework 的操作转换为 RPMI Clock service request，例如：

```text
GET_NUM_CLOCKS
GET_ATTRIBUTES
GET_SUPPORTED_RATES
SET_CONFIG
GET_CONFIG
SET_RATE
GET_RATE
```

典型调用逻辑：

```text
Linux clk op
  ↓
构造 tx struct
  ↓
rpmi_mbox_init_send_with_response(...)
  ↓
rpmi_mbox_send_message(...)
  ↓
mailbox channel
  ↓
transport / MPXY
  ↓
PuC
  ↓
response
  ↓
RPMI error → Linux errno
  ↓
Clock Framework result
```

这是后续学 RPMI 最有价值的“规范落地到 Linux 子系统”的样板。

---

# 33. `riscv-sbi-mpxy-mbox.c` 的位置

当前主线它是：

```text
SBI Message Proxy (MPXY)
        ↓
Linux mailbox controller
```

其职责包括：

```text
检测 SBI MPXY extension
初始化 per-CPU MPXY shared memory
枚举 channel
读取 channel attributes
识别 RPMI message protocol channel
设置 notification / MSI
向 Linux mailbox framework 注册 channel
```

于是上层 `clk-rpmi.c` 不必自己直接写 `sbi_ecall()`。

这是典型 Linux 分层：

```text
functional client
  → generic mailbox
    → MPXY transport/controller
      → SBI
```

---

# 34. STM32 remoteproc 与 RISC-V RPMI 怎么联系

短期：

```text
几乎不要强行联系
```

因为：

- STM32MP157 用来把 remoteproc / rpmsg 学扎实；
- RPMI 是 RISC-V platform management 规范；
- K1 才更适合以后观察 RPMI / SBI MPXY / PuC 类架构。

长期可以比较：

```text
STM32MP157:
Linux AP
  → remoteproc
  → boot/manage M4
  → rpmsg IPC

RISC-V platform:
Linux AP
  → RPMI client
  → transport / SBI MPXY
  → platform microcontroller
  → platform management
```

这样对比的价值是理解：

```text
“远端核生命周期管理”
和
“远端管理控制协议”
是两层不同抽象。
```

---

# 35. SpacemiT K1：当前能确定什么

官方产品资料确认：

```text
K1 有 RISC-V RCPU
支持异构双系统
```

SpacemiT Bianbu 的公开技术材料里还能看到 vendor DTS 类似：

```dts
&rcpu {
    mboxes = <&mailbox 0>, <&mailbox 1>;
    mbox-names = "vq0", "vq1";
    memory-region = <&rcpu_mem_0>,
                    <&vdev0vring0>,
                    <&vdev0vring1>,
                    <&vdev0buffer>,
                    <&rsc_table>,
                    <&rcpu_mem_snapshots>;
};
```

这说明：

```text
vendor 软件栈确实存在非常明显的
remoteproc / virtio-rpmsg 风格 RCPU 集成。
```

但当前对 `torvalds/linux` master 的检查没有确认一个对应的 SpacemiT K1 platform remoteproc driver。

因此这是未来非常有价值的工程题：

```text
vendor K1 RCPU support
    ↓
抽取真实硬件机制
    ↓
对比 current remoteproc core
    ↓
识别缺失 binding / driver / mailbox / reset
    ↓
决定是否具备 upstream 价值
```

而不是第 1 周直接“自己写一个驱动”。

---

# 36. 本周的 K1 调研输出应该是什么

不是代码，而是一张 evidence table：

| 问题 | Mainline | Vendor/官方资料 | 结论 |
|---|---|---|---|
| RCPU 核是什么 | 待继续核对 | 官方确认 RCPU | 已知硬件存在 |
| RCPU reset/boot | 待查 | 待查 vendor driver | 不猜 |
| mailbox | mainline SoC mailbox 待对应 | vendor DTS 有 vq0/vq1 | 需源码确认 |
| shared memory | mainline DTS/reserved-memory 待对应 | vendor DTS 有多区域 | 需地址核对 |
| Resource Table | 未确认 platform driver | vendor DTS 有 `rsc_table` | 强烈证据 |
| remoteproc driver | 当前未确认 | vendor tree 待定位 | Week2+ 调研 |
| rpmsg | current generic framework存在 | vendor DTS 有 vring/buffer | 待运行 |
| RPMI | current generic RISC-V implementation存在 | K1 是否启用待查 | 不做假设 |

---

# 37. 第 1 周必须记住的 12 句话

1. `remoteproc` 是 remote CPU 生命周期和资源管理框架。
2. `rpmsg` 是 virtio-based IPC，不负责 remote CPU 的完整生命周期。
3. `RPMI` 是 AP↔PuC 的平台管理协议，不是 remoteproc。
4. `rproc_boot()` 不是简单地 `ops->start()`。
5. `rproc->power` 是 powered-use 引用计数。
6. remote 已经被别的实体启动时，可以走 attach 路径。
7. ELF program segment、resource table、DTS 是三种不同信息来源。
8. DA、PA/bus、Linux VA 必须分开。
9. `RSC_VDEV` 是 remoteproc 进入 virtio/rpmsg 的关键桥梁。
10. vring 放数据，`kick`/mailbox 通知另一端。
11. STM32MP157 当前主线是学习成熟 remoteproc platform driver 的好样板。
12. RPMI 必须以 Ratified v1.0 为规范基线，current Linux implementation 另外单独跟踪。

---

# 38. 第 1 周源码锚点

所有链接都建议 Codex 后续在本地同 commit 对照。

## Linux fixed current snapshot

```text
https://github.com/torvalds/linux/tree/1b78070aaef63512688aebfbc82365ef9d6660f1
```

### remoteproc API

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/include/linux/remoteproc.h
```

### remoteproc core

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/drivers/remoteproc/remoteproc_core.c
```

### sysfs

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/drivers/remoteproc/remoteproc_sysfs.c
```

### STM32 driver

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/drivers/remoteproc/stm32_rproc.c
```

### STM32 binding

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml
```

### RPMI Linux message layer

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/include/linux/mailbox/riscv-rpmi-message.h
```

### RPMI clock client

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/drivers/clk/clk-rpmi.c
```

### SBI MPXY mailbox

```text
https://github.com/torvalds/linux/blob/1b78070aaef63512688aebfbc82365ef9d6660f1/drivers/mailbox/riscv-sbi-mpxy-mbox.c
```

## RPMI normative

```text
https://docs.riscv.org/reference/rpmi/index.html
https://github.com/riscv-non-isa/riscv-rpmi/tree/v1.0
```

## SBI MPXY

```text
https://docs.riscv.org/reference/sbi/index.html
```

---

# 39. 本材料仍然故意不下结论的事项

这些必须交给 Codex 在本地继续验证：

```text
1. 用户具体 STM32MP157 板型与当前 DTS
2. M4 firmware 的实际文件名与来源
3. 当前板上是否启用 OpenAMP/rpmsg sample
4. K1 使用的是 mainline 还是 Bianbu/vendor kernel
5. K1 vendor remoteproc driver 的精确文件路径和 commit
6. K1 RCPU boot/reset/mailbox 的寄存器/固件契约
7. K1 当前固件是否实现 RPMI、通过何种 transport
8. 用户本地交叉工具链版本
```

这不是文档缺陷。

这是为了避免把“没验证”写成“事实”。

---

# 40. 本周结束时的知识链

如果第 1 周学对了，脑中应该得到：

```text
platform driver probe
  ↓
rproc_alloc
  ↓
rproc_add
  ↓
sysfs / auto_boot / consumer requests boot
  ↓
rproc_boot
  ↓
firmware
  ↓
ELF + resource table
  ↓
carveout / vdev / vring
  ↓
load segment
  ↓
platform ->start
  ↓
remote CPU running
  ↓
virtio/rpmsg messaging
  ↓
crash → report → recovery

同时另开一条：
RISC-V AP
  ↓
RPMI client
  ↓
message/service group
  ↓
transport / SBI MPXY
  ↓
PuC
```

第 2 周以后所有深入都应该挂在这两条主链上，而不是继续堆名词。
