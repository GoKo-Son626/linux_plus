# Week 01：建立 remoteproc 主链与 RPMI 边界

日历：2026-08-31 ～ 2026-09-06

预算：20h（5 x 2h + 2 x 5h）

比例：remoteproc/STM32 15h，RPMI/K1 5h

## 本周结束时必须做到

1. 闭卷区分 remoteproc、virtio、vring、rpmsg、mailbox、RPMI、SBI MPXY。
2. 闭卷画出 `rproc_boot()` 到平台 `ops->start()` 的真实调用链。
3. 能用一个具体例子解释 DA、AP bus/PA 与 Linux VA。
4. 能按 probe -> DT/resources -> ops -> add 的顺序阅读 `stm32_rproc.c`。
5. 至少取得一项 `[R]`：`stm32_rproc.o` 构建通过，或 STM32 板端 remoteproc sysfs 闭环通过。
6. 能说明 RPMI v1.0 的五个抽象，并定位 Linux 当前的 message/MPXY/Clock/System-MSI 文件。
7. 输出 K1 vendor/mainline 证据矩阵；未知项必须保持未知。

## 每日任务

### 周一 2h：总模型与源码索引

- 读 `Documentation/staging/remoteproc.rst`、`rpmsg.rst`。
- 定位 `struct rproc`、`struct rproc_ops`、`rproc_boot()`、`RSC_VDEV`。
- 闭卷回答：rpmsg 已能发消息，为什么仍需要 remoteproc？
- 产出 `notes/01_overview.md`，只写自己的模型与固定 commit/符号位置。

### 周二 2h：`rproc_boot()` 主链

- 追 `rproc_boot` -> `rproc_fw_boot` -> `rproc_start`。
- 每层记录输入、关键状态、下层调用、失败回滚、输出。
- 单独解释 mutex 与 `power` 引用计数。
- 产出 `notes/02_rproc_boot_trace.md`。

### 周三 2h：ELF、Resource Table 与地址

- 追 ELF sanity、entry、PT_LOAD segment 与 resource table 查找。
- 解释 `RSC_CARVEOUT/DEVMEM/TRACE/VDEV`。
- 画一个 STM32 DA -> AP PA/bus -> Linux VA 示例，不背抽象定义。
- 产出 `notes/03_resource_table_addressing.md`。

### 周四 2h：只学够用的 virtio/rpmsg bridge

- 追 `RSC_VDEV`、`rproc_vdev`、vring、`rproc_vq_interrupt()` 与 `kick()`。
- 明确：数据在共享 buffer/vring；mailbox/IPI 只传通知。
- 产出 `notes/04_rpmsg_bridge.md`。

### 周五 2h：STM32 平台映射

- 读 `stm32_rproc_probe()`、`st_rproc_ops`、`stm32_rproc_prepare()`。
- 对照 `st,stm32-rproc.yaml`，区分 DT 平台资源与 firmware resource table。
- 产出 `notes/05_stm32_driver_map.md`。

### 周六 5h：真实工程证据

1. 保存 commit、compiler、config 与完整命令。
2. 优先构建 `drivers/remoteproc/stm32_rproc.o`；若板卡已可连接，可改做 sysfs start/stop 只读+受控写闭环。
3. 保存第一条真实错误、exit code 与产物 hash，禁止只贴最后一屏日志。
4. 自写不超过 800 中文字的 remoteproc 总结。

构建前展开完整 Linux 树：

```bash
./rproc/scripts/bootstrap_sources.sh --full-linux
```

当前本机已有 `arm-none-linux-gnueabihf-gcc 15.2.1`、Clang/LLD 22.1.8 与 dt-schema 2026.6；交叉目标 smoke test 和 STM32 remoteproc binding 校验已通过。真实 `stm32_rproc.o` 构建仍须按本周任务保存完整命令、config、日志、exit code 与产物 hash，不能用 smoke test 代替。

### 周日 5h：RPMI 入门、K1 gap、周测

- 读 RPMI v1.0 Introduction、message header、service-group 总表。
- 追一个 `clk-rpmi.c` GET_RATE/SET_RATE 请求到 mailbox/MPXY。
- 建 K1 mainline/vendor/hardware/unknown 四列矩阵。
- 闭卷完成 `tests/conceptual_questions.md`，填写 `completion_report.md`。

## 验收门槛

- 概念测试 >= 80/100。
- boot trace 关键节点与前后顺序 >= 8/10，且 `ops->start()` 位置正确。
- Build 或 STM32 runtime 至少一项有 `[R]` 证据。
- K1 gap matrix 不含无来源的确定性陈述。
- completion report、实际用时、blocker、三条错题/修正均已填写。

执行检查：

```bash
./rproc/scripts/check_week01.sh
```

检查脚本只验证证据是否齐全，不替代 Codex 对答案正确性的人工评分。
