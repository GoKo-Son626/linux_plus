# 第 1 周学习计划、验收、题目与诊断

> 周预算：20h  
> 工作日：5 × 2h  
> 周末：2 × 5h  
> 本周比例：remoteproc 主线约 15h；RPMI 约 5h  
> 原则：**理解 + 源码定位 + 实际命令 + 输出验收**，不以“看完多少页”作为完成标准。

---

# 0. 第 1 周最终目标

本周结束后，不要求会写一个新 SoC 的 remoteproc driver。

必须做到：

```text
A. 能用自己的话区分：
   remoteproc / virtio / vring / rpmsg / mailbox / RPMI / SBI MPXY

B. 能从 rproc_boot() 手动画出：
   firmware → parse → resource → load → ops->start 的真实链

C. 能解释：
   DA / PA(bus) / Linux VA

D. 能读懂 STM32 rproc probe + rproc_ops + DT binding 的骨架

E. 能在板上或源码环境完成至少一个真实验证：
   - 编译 stm32_rproc.o
   或
   - 操作/观察 STM32 remoteproc sysfs

F. 能说清 RPMI v1.0 的五个抽象，
   并能在当前 Linux 找到 RPMI message / MPXY / Clock / System MSI 实现

G. 能明确指出：
   K1 当前哪些是已验证事实、哪些仍是 vendor/mainline gap
```

完成条件不是“学习 20h”，而是后面的验收通过。

---

# 1. 工作日 1：先把整个地图搭起来（2h）

## 目标

只回答：

```text
remoteproc 到底解决什么问题？
为什么已经有 mailbox/rpmsg 还需要 remoteproc？
```

## 30 min：读概念

读：

```text
Documentation/staging/remoteproc.rst
Documentation/staging/rpmsg.rst
```

只记录 8 个词：

```text
rproc
rproc_ops
firmware
resource table
RSC_VDEV
virtio
vring
rpmsg
```

不要抄长篇定义。

---

## 45 min：建立源码索引

在 Linux 树：

```bash
git status --short
git rev-parse HEAD

rg -n "struct rproc_ops" include/linux/remoteproc.h
rg -n "struct rproc \{" include/linux/remoteproc.h
rg -n "^int rproc_boot\(" drivers/remoteproc/remoteproc_core.c
rg -n "^int rproc_shutdown\(" drivers/remoteproc/remoteproc_core.c
rg -n "RSC_VDEV" include/linux drivers/remoteproc
```

### 输入

当前 Linux source tree。

### 底层机制

只是源码定位，不修改任何内容。

### 输出

必须保存到学习笔记：

```text
当前 commit
5 个关键文件
5 个关键符号所在行
```

### 后续用途

以后任何 AI 解释都能快速回源码核实。

---

## 45 min：闭卷画第一版图

不看文档，写：

```text
Linux
  → remoteproc
  → platform driver
  → remote CPU

Resource Table
  → RSC_VDEV
  → virtio
  → vring
  → rpmsg
```

然后再看 `01_...Technical_Baseline.md` 修正。

### 当日通过标准

必须能回答：

> rpmsg 能发消息，为什么还要 remoteproc？

正确核心：

```text
因为消息传输和 remote CPU 生命周期/固件/资源管理不是同一层职责。
```

---

# 2. 工作日 2：啃透 `rproc_boot()`（2h）

## 目标

从源码而不是教程理解启动路径。

---

## 60 min：逐函数 trace

按顺序定位：

```bash
rg -n "^int rproc_boot\(" drivers/remoteproc/remoteproc_core.c
rg -n "^static int rproc_fw_boot\(" drivers/remoteproc/remoteproc_core.c
rg -n "^static int rproc_start\(" drivers/remoteproc/remoteproc_core.c
rg -n "rproc_load_segments" drivers/remoteproc
rg -n "rproc_handle_resources" drivers/remoteproc
```

对每一层只写：

```text
输入
关键状态
调用下层
失败回滚
输出/状态
```

---

## 30 min：专门研究 `power` 和 `lock`

找到：

```text
atomic_inc_return(&rproc->power)
atomic_dec...
rproc->lock
```

回答：

1. 为什么第二个 caller 调 `rproc_boot()` 不应该再次 reset remote CPU？
2. 为什么 shutdown 也需要 power refcount？
3. 为什么 rproc state 操作需要 mutex？

---

## 30 min：闭卷重画调用链

目标最少包含：

```text
rproc_boot
request_firmware
rproc_fw_boot
rproc_parse_fw
rproc_handle_resources
rproc_alloc_registered_carveouts
rproc_start
rproc_load_segments
ops->start
RPROC_RUNNING
```

### 当日通过标准

顺序错 2 个以上：第二天开始前重做 20 min。

---

# 3. 工作日 3：ELF + Resource Table + 地址（2h）

## 目标

解决 remoteproc 最容易混乱的中间层。

---

## 40 min：ELF helper

定位：

```bash
rg -n "rproc_elf_(sanity_check|get_boot_addr|load_segments|find_loaded_rsc_table)" \
  drivers/remoteproc include/linux
```

回答：

```text
ELF entry point 去哪里？
program segment 谁加载？
resource table 怎么找到？
```

---

## 40 min：Resource Table

```bash
rg -n "struct resource_table" include/linux
rg -n "enum fw_resource_type" include/linux
rg -n "RSC_(CARVEOUT|DEVMEM|TRACE|VDEV)" include/linux drivers/remoteproc
```

手写表：

| Type | 谁提出 | Host 做什么 | Remote 最终得到什么 |
|---|---|---|---|
| CARVEOUT | firmware | 分配/映射 | memory |
| DEVMEM | firmware | IOMMU/映射 | device access |
| TRACE | firmware | 暴露读取 | log buffer |
| VDEV | firmware | 建 virtio/vring | virtio device |

---

## 40 min：DA / PA / VA

只画一个地址例子，不要堆概念：

```text
Remote DA
  ↓ translation
AP bus/physical
  ↓ map
Linux kernel VA
```

然后读：

```bash
rg -n "rproc_da_to_va" drivers/remoteproc include/linux
rg -n "pa_to_da|dma-ranges" drivers/remoteproc/stm32_rproc.c
```

### 当日通过标准

给出下面判断并解释：

```text
DA == PA ?
```

正确答案：

```text
不保证。
是否相等取决于平台地址映射。
```

---

# 4. 工作日 4：只学够用的 virtio/rpmsg（2h）

## 目标

不要在本周深入 rpmsg driver API；只把 remoteproc 接到 IPC 的桥弄明白。

---

## 45 min：源码链

```bash
rg -n "RSC_VDEV" drivers/remoteproc
rg -n "rproc_vdev" drivers/remoteproc include/linux/remoteproc.h
rg -n "rproc_vq_interrupt" drivers/remoteproc
rg -n "\.kick|->kick" drivers/remoteproc
```

画：

```text
RSC_VDEV
  ↓
rproc_vdev
  ↓
virtio device
  ↓
2 vrings
  ↓
virtqueue
  ↓
rpmsg
```

---

## 45 min：数据与通知分离

必须能解释：

```text
数据在哪里？
  → shared vring/buffer

为什么还需要 mailbox / IPI？
  → 告诉另一端“去检查队列”

kick 传的是什么？
  → vqid/notification，不是把整个 rpmsg payload 复制过去
```

---

## 30 min：源码验证 STM32

```bash
rg -n "STM32_MBX_VQ|rproc_vq_interrupt|stm32_rproc_kick" \
  drivers/remoteproc/stm32_rproc.c
```

### 当日通过标准

不能再说：

```text
mailbox 就是 rpmsg 数据区
```

如果还混，回到 vring 数据结构再学，不往后赶。

---

# 5. 工作日 5：读懂 STM32MP157 平台驱动骨架（2h）

## 目标

第一次把 remoteproc core 映射到真实 SoC。

---

## 40 min：probe

```bash
rg -n "stm32_rproc_probe|devm_rproc_alloc|rproc_add" \
  drivers/remoteproc/stm32_rproc.c
```

输出：

```text
probe
→ alloc rproc
→ DT
→ memory translation
→ M4 state
→ mailbox
→ rproc_add
```

---

## 40 min：ops

```bash
rg -n "st_rproc_ops|stm32_rproc_(prepare|start|stop|attach|detach|kick)" \
  drivers/remoteproc/stm32_rproc.c
```

分类：

```text
通用 ELF helper
平台硬件 callback
```

---

## 40 min：DT binding

```bash
sed -n '1,260p' \
  Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml
```

至少理解：

```text
compatible
reg
resets
reset-names
memory-region
mboxes
mbox-names
firmware-name
st,auto-boot
```

### 当日通过标准

回答：

> 为什么 remote firmware resource table 已经描述资源，DTS 还需要 memory-region / mailbox / reset？

核心：

```text
DTS 描述 AP/Linux 侧的硬件与平台连接；
resource table 描述 remote firmware 的资源需求/能力；
视角不同，不能互相完全替代。
```

---

# 6. 周末 1：5h remoteproc 实操与验证

这一天必须产出真实工程证据。

---

# 6.1 30 min：环境固定

在本地 Linux tree：

```bash
git rev-parse HEAD
git describe --always --dirty
uname -a || true

${CC:-gcc} --version | head
arm-linux-gnueabihf-gcc --version | head || true
```

把输出记录到：

```text
week1/environment.txt
```

如果本地没有 ARM cross compiler：

```text
不要假装 build pass。
记录 blocker，继续源码/DT 校验任务。
```

---

# 6.2 90 min：编译 `stm32_rproc.o`

推荐在干净的独立 output dir，避免污染源码。

前提：

```text
arm-linux-gnueabihf-* 可用
```

示例：

```bash
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

make O=out-rproc multi_v7_defconfig

grep -E '^CONFIG_(ARCH_STM32|REMOTEPROC|STM32_RPROC|RPMSG|RPMSG_VIRTIO)=' \
  out-rproc/.config || true
```

如 `CONFIG_STM32_RPROC` 未打开，可通过交互配置或：

```bash
./scripts/config --file out-rproc/.config -e STM32_RPROC
make O=out-rproc olddefconfig
```

然后：

```bash
make O=out-rproc -j"$(nproc)" \
  drivers/remoteproc/stm32_rproc.o
```

### 必须保存

```text
command
exit code
compiler version
config entries
out-rproc/drivers/remoteproc/stm32_rproc.o 是否存在
```

### 失败怎么办

不能只写“编译失败”。

必须分类：

```text
toolchain
Kconfig dependency
header/API
link/build-system
environment
```

并保存第一条真正错误，而不是最后 200 行噪声。

---

# 6.3 45 min：DT schema 校验（环境具备时）

```bash
make O=out-rproc dt_binding_check \
  DT_SCHEMA_FILES=Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml
```

如果缺少 `dtschema` 等 Python 依赖：

```text
记录为 environment blocker
不要为了本周强行修 2 小时 Python 环境
```

重点是明白：

```text
DTS binding 可以机器校验，不只是给人看的说明书。
```

---

# 6.4 90 min：STM32 板上 sysfs 闭环

如果板上存在：

```bash
ls /sys/class/remoteproc/
```

先只读：

```bash
for r in /sys/class/remoteproc/remoteproc*; do
  echo "=== $r ==="
  for f in name state firmware recovery coredump; do
    [ -r "$r/$f" ] && printf '%-10s ' "$f" && cat "$r/$f"
  done
done
```

另一个终端：

```bash
sudo dmesg -w
```

如果确认 firmware 配置正确且当前是 offline：

```bash
R=/sys/class/remoteproc/remoteproc0

echo start | sudo tee "$R/state"
cat "$R/state"

echo stop | sudo tee "$R/state"
cat "$R/state"
```

每次操作建立闭环：

```text
echo start
  ↓
state_store()
  ↓
rproc_boot()
  ↓
STM32 driver ops
  ↓
kernel log
  ↓
running
```

如果板子暂时不能跑：

```text
用“build + source trace”完成本周最低实操；
硬件项标记 deferred，不判本周失败。
```

---

# 6.5 45 min：写 1 页“我现在怎么理解 remoteproc”

禁止复制 AI。

必须自己写，最多 800 中文字。

必须包含：

```text
remoteproc 的职责
boot 调用链
resource table
DA/PA/VA
RSC_VDEV → rpmsg
STM32 平台层做什么
```

下周 Codex 用这份自述判断真实掌握程度。

---

# 7. 周末 2：5h RPMI 入门 + K1 差距调查

## 目标

不是把 RPMI 规范看完。

只建立：

```text
规范坐标系
+
当前 Linux 落地位置
+
与 remoteproc 的边界
```

---

# 7.1 60 min：读 RPMI v1.0 Introduction

固定：

```text
https://github.com/riscv-non-isa/riscv-rpmi/tree/v1.0
```

只摘：

```text
Transport
Messaging Protocol
Service Groups
Client
Context
AP
PuC
runtime discovery
```

闭卷写：

```text
RPMI 是什么？
为什么它不是 remoteproc？
```

---

# 7.2 45 min：读 message header

当前 Linux tree：

```bash
sed -n '1,260p' include/linux/mailbox/riscv-rpmi-message.h
```

定位：

```bash
rg -n "rpmi_message_header|rpmi_mbox_message|RPMI_SRVGRP_" \
  include/linux/mailbox/riscv-rpmi-message.h
```

必须看懂：

```text
servicegroup_id
service_id
flags
datalen
token
```

不要求背 flags bit。

---

# 7.3 60 min：追一条 RPMI Clock request

```bash
rg -n "rpmi_mbox_init_send_with_response|RPMI_CLK_SRV_" \
  drivers/clk/clk-rpmi.c
```

挑一个：

```text
GET_RATE
或
SET_RATE
```

手动画：

```text
Linux clk API
→ clk-rpmi
→ rpmi_mbox_message
→ mbox_send_message
→ MPXY mailbox / transport
→ PuC
→ response
→ Linux errno/result
```

---

# 7.4 45 min：SBI MPXY

```bash
rg -n "SBI_EXT_MPXY|SBI_MPXY_MSGPROTO_RPMI_ID|mbox_controller" \
  drivers/mailbox/riscv-sbi-mpxy-mbox.c
```

回答：

```text
为什么 clk-rpmi.c 不直接调 sbi_ecall？
```

正确核心：

```text
因为 Linux 通过 mailbox abstraction 隔离功能 client 与 transport/controller。
```

---

# 7.5 60 min：K1 vendor vs mainline evidence matrix

主线：

```bash
rg -n -i "rcpu|remoteproc|rpmi|mpxy" \
  arch/riscv/boot/dts/spacemit drivers/remoteproc drivers/mailbox \
  2>/dev/null || true
```

如果本地有 Bianbu/vendor kernel：

```bash
rg -n -i "rcpu|remoteproc|rproc|vdev0vring|rsc_table|mbox-names" \
  <vendor-kernel-path>
```

输出表：

```text
feature
mainline evidence
vendor evidence
hardware docs evidence
unknown
```

本周不修改 K1 驱动。

---

# 7.6 30 min：周测

完成下面题目，不看答案。

---

# 8. 第 1 周概念测试题

## A 组：必须全对（10 题）

### 1

`remoteproc` 和 `rpmsg` 的核心职责差异是什么？

### 2

`rproc_boot()` 是否等价于：

```c
rproc->ops->start(rproc);
```

为什么？

### 3

`rproc->power` 大致解决什么问题？

### 4

`RPROC_DETACHED` 时调用 `rproc_boot()` 为什么可能不加载 firmware？

### 5

Resource Table 和 Device Tree 是不是同一个东西？

### 6

DA、PA、VA 是否总相等？

### 7

`RSC_VDEV` 在整条链中的作用是什么？

### 8

rpmsg payload 通常已经写到共享 vring/buffer 后，为什么还需要 `kick()`？

### 9

STM32 `stm32_rproc.c` 中哪些部分可以复用 generic ELF helper？

至少说出两个。

### 10

RPMI 与 remoteproc 为什么不是竞争关系？

---

## B 组：源码追踪（8 题）

### 11

从：

```text
echo start > /sys/class/remoteproc/remoteprocX/state
```

开始，写出直到 `rproc_boot()` 的函数关系。

### 12

`rproc_fw_boot()` 中，resource handling 在 platform `->start()` 之前还是之后？

为什么？

### 13

`rproc_start()` 为什么要在 `->start()` 前 load ELF segments？

### 14

STM32 的 `dma-ranges` 在驱动中解决什么问题？

### 15

STM32 `vq0/vq1` mailbox 与 vring 的关系是什么？

### 16

找到当前 Linux `struct rproc_ops`，说明为什么只看旧版 remoteproc.rst 可能出错。

### 17

当前 Linux RPMI message header 有哪些字段？

### 18

`clk-rpmi.c` 为什么通过 mailbox API 而不是把 MPXY 细节写进 clock driver？

---

## C 组：判断题（7 题）

### 19

“有 RPMI 就不需要 remoteproc。”

### 20

“remoteproc 启动 firmware，所以所有 remote processor 都必须由 Linux 启动。”

### 21

“mailbox 负责保存 rpmsg payload。”

### 22

“Resource Table 只能描述内存。”

### 23

“RPMI GitHub main 比 v1.0 tag 更新，所以学习规范应以 main 为准。”

### 24

“Linux 当前出现 RPMI Clock client，说明 RPMI v1.0 只有 Clock service group。”

### 25

“找到 K1 vendor DTS 中的 `&rcpu` 就足以证明当前 torvalds/linux 已支持 K1 remoteproc。”

---

# 9. 答案判定要点

## A

1. `remoteproc` 生命周期/firmware/resource；`rpmsg` virtio-based messaging。
2. 否；前面有 lock/refcount/firmware/sanity/resource/carveout/ELF load 等。
3. 多个用户共享“保持 remote processor powered”的需求，避免重复 boot/过早 shutdown。
4. DETACHED 表示可能由外部实体已 boot，core 可 attach。
5. 不是；DTS 是平台硬件描述，resource table 是 remote firmware 的资源/能力契约。
6. 不保证。
7. 宣告 virtio device，是 remoteproc 进入 virtio/rpmsg 的关键资源 entry。
8. 数据与 notification 分离；kick 告诉 remote 检查对应 queue。
9. 如 `rproc_elf_load_segments`、`rproc_elf_sanity_check`、`rproc_elf_get_boot_addr`、`rproc_elf_find_loaded_rsc_table`。
10. 一个是 Linux remote CPU 管理 framework，一个是 platform management message protocol。

## B

11. sysfs `state_store()` → `rproc_boot()`。
12. 之前；先把 remote 启动所需资源准备好。
13. remote CPU 启动后要能从正确内存和 entry 执行。
14. AP bus/physical 与 M4 device address 翻译。
15. vring 保存队列/数据，mailbox 做 vq notification。
16. 当前 header 的 ops 已更丰富；源码头文件是 API 真相。
17. `servicegroup_id/service_id/flags/datalen/token`。
18. 分离 functional client 与 transport；可复用 Linux mailbox abstraction。

## C

全部：

```text
19 False
20 False
21 False
22 False
23 False
24 False
25 False
```

---

# 10. 评分

```text
A组 10 × 4 = 40
B组  8 × 5 = 40
C组  7 × ~3 = 20
总分         = 100
```

判定：

```text
90~100：
  可以进入 Week2，并加大源码/代码任务。

80~89：
  可以进入 Week2，但将错题前置复习。

65~79：
  Week2 前 2~3h 必须补 remoteproc 主链；
  不增加 RPMI 深度。

<65：
  不推进新主题。
  先重新建立 remoteproc / resource / rpmsg 三层模型。
```

---

# 11. 源码口述验收

Codex 下周开始前应随机问 5 个，不让用户看文档。

题库：

```text
1. rproc_boot 到 ops->start 中间发生什么？
2. 为什么有 cached resource table？
3. DA 和 PA 为什么可能不同？
4. RSC_VDEV 后面发生什么？
5. mailbox 和 vring 各负责什么？
6. DETACHED 和 OFFLINE 的语义区别？
7. STM32 prepare 为什么遍历 memory-region？
8. RPMI Context 包含什么？
9. RPMI 和 SBI MPXY 是什么关系？
10. K1 目前哪些 remoteproc 结论还没有被 mainline 证实？
```

只要答不清的，就是下周要动态补的知识，而不是“已经学过所以跳过”。

---

# 12. 工程验收矩阵

本周最低：

| 项目 | 必须 | 通过标准 |
|---|---:|---|
| 概念题 ≥80 | 是 | 分数记录 |
| `rproc_boot` 源码链 | 是 | 闭卷顺序基本正确 |
| Resource Table 类型 | 是 | 4 类能解释 |
| DA/PA/VA | 是 | 不再混淆 |
| STM32 driver probe/ops | 是 | 能指到源码 |
| RPMI 5 抽象 | 是 | 能用自己的话说明 |
| RPMI Linux source map | 是 | 能找到 4 个关键文件 |
| `stm32_rproc.o` build | 二选一 | 有真实 build log |
| STM32 sysfs runtime | 二选一 | 有真实 kernel/sysfs log |
| K1 vendor/mainline matrix | 是 | 不允许猜测填空 |

如果 STM32 硬件暂时不能跑：

```text
build 必须尽量完成
+
runtime 标记 deferred
```

不是伪造 runtime 成功。

---

# 13. 本周建议仓库产物

Codex 在本地最终应该留下：

```text
week01/
├── notes/
│   ├── 01_overview.md
│   ├── 02_rproc_boot_trace.md
│   ├── 03_resource_table_addressing.md
│   ├── 04_rpmsg_bridge.md
│   ├── 05_stm32_driver_map.md
│   └── 06_rpmi_map.md
│
├── evidence/
│   ├── environment.txt
│   ├── build_stm32_rproc.log
│   ├── remoteproc_sysfs.log
│   └── k1_gap_matrix.md
│
├── tests/
│   ├── week01_answers.md
│   └── week01_score.md
│
└── completion_report.md
```

无需把 AI 参考文档重新复制到这些笔记里。

笔记只写：

```text
自己真正理解的
+
源码证据
+
实际输出
+
错误与修正
```

---

# 14. `completion_report.md` 模板

```markdown
# Week 01 Completion

## Time
- planned: 20h
- actual:
- completion:

## Source pins
- Linux:
- RPMI:
- vendor kernel:

## What I can explain without notes
- [ ] remoteproc vs rpmsg
- [ ] rproc_boot chain
- [ ] resource table
- [ ] DA/PA/VA
- [ ] STM32 platform role
- [ ] RPMI abstractions
- [ ] RPMI vs remoteproc

## Verification
- stm32_rproc.o build:
- DT binding check:
- STM32 remoteproc runtime:
- K1 vendor/mainline investigation:

## Test
- conceptual:
- source trace:
- total:

## Three things I was wrong about
1.
2.
3.

## Blockers
-

## Next week should
-

## Next week should NOT
-
```

这份 report 是 Week2 动态规划的主要输入。

---

# 15. 给 Codex 的动态调整规则

下周开始时：

```text
if conceptual_score < 80:
    不加新 RPMI 深度
    补 remoteproc core

if rproc_boot_trace 不稳:
    Week2 前 2h 继续 core trace

if build_failed due API/code:
    优先修 build
elif build_failed only environment:
    不阻塞概念推进

if STM32 runtime passed:
    Week2 增加 rpmsg/OpenAMP runtime
else:
    先解决 firmware/DTS/board 链

if K1 vendor driver found:
    Week2/3 建 vendor→mainline diff
else:
    不凭空写 K1 platform driver

if week1_score >= 90 and runtime/build strong:
    Week2 可以提前进入：
      resource table deep dive
      remoteproc_virtio
      rpmsg endpoint
      STM32 firmware/openamp
```

---

# 16. 第 1 周不要做的事

本周故意不做：

```text
× 通读全部 RPMI v1.0
× 通读整个 drivers/remoteproc
× 自己实现完整 rpmsg driver
× 写 K1 remoteproc 主线补丁
× 深入 crash coredump ELF 格式
× 研究全部 RPMI service groups
× 同时学习 OpenSBI 全部 MPXY 实现
× 为“学得多”而跳过 STM32 实际验证
```

这些都会让第 1 周主线失焦。

---

# 17. 本周成功的判断

真正成功不是：

> “remoteproc、rpmsg、RPMI 都看过了。”

而是：

> 看到一个陌生 remoteproc platform driver 时，已经知道应该按  
> `probe → rproc_alloc → DT/resources → rproc_ops → rproc_add → boot path → resource table → virtio/rpmsg`  
> 的顺序拆它。

同时看到 RPMI code 时，知道应该按：

> `service group → message → mailbox/transport → MPXY/real transport → PuC`

去拆。

做到这两点，第 1 周就完成了。
