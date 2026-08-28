# Codex 输入基准与长期学习协作契约

> 项目：Linux 内核 `remoteproc (rproc)` + RISC-V `RPMI`  
> 用途：作为 ChatGPT 网页端提供给 Codex 的**高可信参考输入**。  
> 时间点：2026-08-28  
> 当前阶段：第 1 周 / 约 5 个月长期学习周期  
> 核心原则：**正确性 > 可验证性 > 可持续性 > token 效率 > 文档观感**

---

## 0. Codex 先读这个文件

这套材料不是让 Codex “照抄教程”，而是给 Codex一个**事实基线、源码锚点、学习验收合同**。

Codex 在本地拥有更强的上下文：

- 当前实际 Linux 源码树；
- STM32MP157 / SpacemiT K1 的本地资料、SDK、DTS、日志；
- 每周真实代码、命令输出和 Git 历史；
- Gemini 与 ChatGPT 网页端的周度参考材料。

所以职责划分必须固定：

| 角色 | 主要职责 | 不应该做 |
|---|---|---|
| ChatGPT 网页端 | 外部事实核验、源码/规范基准、学习结构审查 | 假装知道本地运行结果 |
| Gemini | 周度补充检索/资料汇总，可作为第二意见 | 其结论不得自动升级为事实 |
| Codex | 读取本地源码、执行命令、写代码、编译测试、记录进度、动态调整 | 不得因参考文档写了“可编译”就跳过本地验证 |
| 用户 | 学习、实操、回答测试题、反馈理解程度与硬件结果 | 不需要手工维护重复进度信息 |

---

# 1. 证据优先级：发生冲突时按此裁决

从高到低：

1. **本地实际运行结果 + 与该结果完全对应的源码 commit**
2. **已 Ratified 的规范 / Linux 官方 release 对应源码**
3. **`torvalds/linux` 当前 master 的固定 commit**
4. **官方芯片/板卡文档、官方 SDK / vendor kernel**
5. **lore.kernel.org 邮件列表和已合入 commit 历史**
6. Gemini / ChatGPT 生成的技术解释
7. 第三方博客、论坛、搜索摘要

任何较低级别材料与高级别证据冲突，都必须以高级别为准。

---

# 2. 本周期的固定源码基线

## 2.1 Linux

### 可复现学习基线

- Linux mainline release：`v7.2`
- 官方发布日期：2026-08-16
- 如果用于实际稳定运行，可额外参考 `v7.2.1` stable（2026-08-27）

### 前沿源码情报基线

2026-08-28 检查时：

```text
repository: torvalds/linux
branch: master
commit: 1b78070aaef63512688aebfbc82365ef9d6660f1
```

规则：

- **学习概念、实验复现**优先 `v7.2`；
- **检查 API 是否已经变化、RPMI 最新主线实现**使用上面的 master commit；
- 文档里严禁把 master commit 叫作“Linux 7.3 正式版”；
- 以后每周更新 master 时，必须记录新的 commit，不允许只写“最新源码”。

官方入口：

- https://www.kernel.org/
- https://github.com/torvalds/linux

---

## 2.2 RPMI

规范基线固定为：

```text
RISC-V Platform Management Interface Specification
Version: v1.0
Date: 2025-07-16
Status: Ratified
Git tag: v1.0
repository: riscv-non-isa/riscv-rpmi
```

规范入口：

- https://docs.riscv.org/reference/rpmi/index.html
- https://github.com/riscv-non-isa/riscv-rpmi/tree/v1.0

**禁止把 GitHub `main` 分支上仍带 “Draft” 字样的工作树当成规范基准。**

如需了解后续变化，可以额外对比 `main`，但必须明确标为：

```text
NON-NORMATIVE / POST-v1.0 DEVELOPMENT
```

---

# 3. 每条技术结论必须带验证级别

Codex 后续产出的教程、代码解释和周报，推荐使用以下 4 个标签：

### `[S] Source-verified`

已经在固定源码 commit / Ratified 规范中直接确认。

例如：

```text
[S] 当前 rproc_boot() 会获取 rproc->lock，并增加 power 引用计数。
```

### `[R] Runtime-verified`

已经在本地板卡或编译环境实际验证，并保存命令和输出。

例如：

```text
[R] STM32MP157 上 /sys/class/remoteproc/remoteproc0/state
    从 offline -> running。
```

### `[P] Platform-dependent`

实现依赖 SoC、固件、DTS、bootloader 或 vendor kernel，不能从框架代码泛化。

例如：

```text
[P] 某个 mailbox 通道编号由平台 DT / 驱动定义。
```

### `[H] Hypothesis / To verify`

目前只是合理推测，必须安排验证。

例如：

```text
[H] K1 vendor RCPU 驱动可以直接迁移到当前主线 remoteproc API。
```

**禁止将 `[H]` 改写成确定事实。**

---

# 4. “100% 可编译”的正确含义

长期任务中原来的“所有代码必须 100% 可编译”需要收紧定义。

只有满足以下全部条件，Codex 才能写：

```text
[R] Build verified
```

必须同时记录：

1. Linux commit；
2. `.config` 或 defconfig；
3. `ARCH`；
4. `CROSS_COMPILE` / compiler 版本；
5. 完整构建命令；
6. exit code；
7. 关键输出；
8. 生成对象/镜像路径。

否则只能写：

```text
[S] API/source verified, build not executed
```

**原因：** 一个内核驱动的 API 全部真实，也不代表在用户当前工具链、Kconfig、DTS 与目标板环境中已经实际编译/运行。

---

# 5. 三个主题永远分开：remoteproc ≠ rpmsg ≠ RPMI

这是整个 5 个月最重要的边界之一。

```text
remoteproc
  负责：remote CPU 生命周期、固件加载、资源准备、启动/停止、崩溃恢复

remoteproc + Resource Table
  可发现：RSC_VDEV 等资源

virtio/rpmsg
  负责：建立 virtqueue / channel / endpoint，做 AP 与 remote CPU 的消息通信

RPMI
  负责：AP 与 platform microcontroller(PuC)之间的平台管理/控制协议
  是独立的“消息协议 + Service Group”体系
```

RPMI **不是** remoteproc 的升级版，也**不是** rpmsg 的另一个名字。

两者未来可能在同一异构 SoC 中同时存在，但解决的是不同问题。

---

# 6. 第 1 周学习权重

本周不做 50:50 平分。

```text
remoteproc / ELF / Resource Table / virtio-rpmsg bridge / STM32MP157 : 15h
RPMI v1.0 + 当前 Linux RPMI implementation reconnaissance           :  5h
总计                                                              : 20h
```

原因：

1. `remoteproc` 是当前第一主线；
2. STM32MP157 有成熟主线 `stm32_rproc.c`，适合建立真正源码闭环；
3. rpmsg 只学习到能理解 `RSC_VDEV -> virtio -> vring -> rpmsg`；
4. RPMI 第 1 周只建立“它是什么、在哪里、Linux 当前已经实现什么”；
5. 等 remoteproc 主线扎稳，再深入 RPMI transport / messaging / BASE / service groups / MPXY。

---

# 7. 平台策略

## STM32MP157：第一阶段主实操平台

优点：

- Linux 主线存在真实 `drivers/remoteproc/stm32_rproc.c`；
- 有正式 DT binding；
- Cortex-A7 Linux + Cortex-M4 是非常典型的 AMP；
- 能完整观察 reset、reserved-memory、mailbox、ELF、resource table、virtio/rpmsg。

因此：

```text
第一阶段：STM32MP157 = “验证 remoteproc 框架”的主平台
```

---

## SpacemiT K1：第 1 周只做差距分析

已知：

- 官方资料确认 K1 有 RISC-V RCPU；
- SpacemiT Bianbu 文档中能看到 `&rcpu`，以及：
  - `mboxes = <&mailbox 0>, <&mailbox 1>;`
  - `mbox-names = "vq0", "vq1";`
  - `memory-region = <...>;`
- 当前检查 `torvalds/linux` master 时，没有确认到明确的 K1 RCPU `remoteproc` 平台驱动。

因此第 1 周：

```text
允许：
  vendor DTS / vendor driver / mainline DTS 对比
  找 K1 RCPU boot/reset/mailbox/shared-memory 证据
  输出 upstream gap list

禁止：
  凭想象写一个“100% 可运行”的 K1 remoteproc driver
  把 vendor 属性直接当 mainline binding
```

以后若在官方 vendor kernel 中找到真实 RCPU remoteproc 驱动，再以：

```text
vendor implementation
    ↓ diff
current remoteproc core API
    ↓ binding cleanup
mainline candidate
```

的路线推进。

---

# 8. Codex 每周读取顺序

每周开始时按顺序：

```text
1. 本仓库 README / 本文件
2. week_state.yaml
3. 上周 completion_report
4. 上周错题/编译失败/硬件日志
5. ChatGPT 本周参考文档
6. Gemini 本周材料
7. 本地 Linux 当前源码
8. 再制定本周任务
```

绝对禁止：

```text
先读 Gemini/ChatGPT 长文
→ 忽略本地历史
→ 从头再讲同样概念
```

---

# 9. 每周 Codex 必须维护的最小状态

建议仓库固定维护：

```text
state/
  week_state.yaml
  misconceptions.md
  source_pins.md
  hardware_matrix.md
```

其中：

## `misconceptions.md`

只记录真正理解错误：

```text
- 日期
- 原错误理解
- 正确模型
- 源码/规范证据
- 是否复测通过
```

## `source_pins.md`

记录每周真正使用过的：

```text
linux_release:
linux_master_sha:
rpmi_tag:
opensbi_version:
vendor_kernel_sha:
```

## `hardware_matrix.md`

```text
STM32MP157:
  board:
  bootloader:
  kernel:
  M4 firmware:
  remoteproc status:
  rpmsg status:

SpacemiT K1:
  board:
  kernel:
  vendor/mainline:
  RCPU firmware:
  RCPU remoteproc:
  RPMI/MPXY:
```

---

# 10. 每周动态调整输入

用户下周只需要给 Codex：

```text
上周学完了，安排这周。
```

Codex 必须自己先从仓库恢复状态，再只补问**确实无法从文件/命令获得**的信息。

建议把以下反馈自动记录为结构化数据：

```yaml
hours_actual: 0
completion_percent: 0
confidence:
  remoteproc_core: 0      # 0~5
  resource_table: 0
  rpmsg_bridge: 0
  stm32_platform: 0
  rpmi: 0

tests:
  conceptual_score: 0
  source_trace_score: 0
  build_pass: false
  hardware_pass: false

blockers: []
misconceptions: []
next_week_adjustments: []
```

---

# 11. 本周期明确禁止的低质量行为

1. 复制十年前教程中的过时 `struct rproc_ops`，不对当前头文件。
2. 把 `Documentation/staging/remoteproc.rst` 当作唯一 API 真相。
3. 将 Device Address、Physical Address、Kernel Virtual Address 混在一起。
4. 将 Resource Table 与 Device Tree 当成同一个东西。
5. 将 mailbox、virtqueue、rpmsg endpoint 当成同一级概念。
6. 将 `rproc_add()` 误写成“同步把 remote CPU 启动起来”。
7. 将 `rproc_boot()` 误写成直接调用平台 `->start()`。
8. 将 `remoteproc` 和 `RPMI` 合并成一套框架。
9. 将 RPMI GitHub `main` 的 Draft 内容覆盖 Ratified v1.0。
10. 在没有本地编译日志时声称“100% 可编译”。
11. 为 K1 编造主线不存在的 binding / API / remoteproc 驱动。
12. 为了完成学习计划而跳过用户真正没理解的前置知识。

---

# 12. 本包阅读顺序

```text
00_Codex_Reference_Contract.md
        ↓
01_Week1_rproc_RPMI_Technical_Baseline.md
        ↓
02_Week1_Learning_Plan_Acceptance_and_Diagnostics.md
        ↓
week1_state.yaml
```

其中：

- `00`：告诉 Codex 如何判断什么是真的；
- `01`：告诉 Codex 第 1 周技术事实基线；
- `02`：告诉 Codex 本周具体怎么学、怎么验收；
- `yaml`：给 Codex 低 token 恢复状态。
