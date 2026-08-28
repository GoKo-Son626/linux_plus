# linux-plus 长期协作记忆

## 项目定位

- 本目录长期保存用户工作之余学习 Linux 的知识、代码、测试和证据。
- 当前 5 个月主线：先系统掌握 Linux remoteproc，再逐步深入 RISC-V RPMI。
- 主要平台：STM32MP157 用于成熟 remoteproc 实操；SpacemiT K1 用于 vendor/mainline 差距调查与后续工程实践。

## 用户背景与教学偏好

- 用户具备 ARMv7-A/Cortex-A9/M4、RTOS 上下文切换、中断/GIC、PUS、EDS/cFS 等嵌入式经验，不需要从 C 语言或操作系统基础重新讲起。
- 讲解先给结论和核心模型，再给源码、命令、机制与输出。
- 任务必须形成“命令 -> 输入 -> 底层机制 -> 预期输出 -> 后续用途”闭环。
- 代码只有经过本地真实构建后才能标记为可编译；硬件结论只有保存板端输出后才能标记为运行验证。

## 周度节奏

- 不安排任何自动定时任务或 6 小时巡检。
- 每周一用户主动通知“上周学完了，安排这周”。
- Codex 必须先回读 `rproc/state/`、上周 completion report、错题、构建日志和板端日志，再安排本周。
- 标准预算 20h：工作日 5 x 2h，周末 2 x 5h。按验收结果推进，不以耗时或看完页数判定完成。
- 每周验收完成后，先更新 `rproc/state/current_handoff.md` 和长期状态，commit + push 并确认干净同步；Codex 明确给出 safe-to-compact 后，用户再执行一次 `/compact`。
- 当前代理不能代替用户触发界面 `/compact`；若系统自动压缩或进入新会话，也必须按 `rproc/state/WEEKLY_CONTEXT_PROTOCOL.md` 的顺序恢复。

## 参考材料边界

- `rproc/chatgpt-web/`：可作为高质量候选基线，仍须对官方源码/规范复核。
- `rproc/gemini-spark/`：作为第二意见与检索线索；首周产物存在严重事实错误，不能直接学习。
- 低级证据与高级证据冲突时，优先级为：板端/构建证据 > 固定源码与 Ratified 规范 > vendor 官方资料 > lore > AI 产物。

## Git 约定

- 学习计划、笔记、题目、答案、审计、证据摘要和可复现脚本进入 Git。
- 外部 Linux/RPMI 源码树与大体积构建目录不进入 Git。
- 每次完成一个可解释的小目标就提交；配置远端后自动 push。不得伪造构建或板端成功。

## 当前状态（2026-08-28）

- Week 1 日历按 2026-08-31 至 2026-09-06 准备；Gemini 参考文件夹沿用其 `2026-08-30_第1周` 命名。
- 官方远端已核实 Linux `v7.2`、stable `v7.2.1`、master 固定 commit 与 RPMI `v1.0`。
- STM32 平台为正点原子 STM32MP157 开发板、串口连接；标准核心板通常是 STM32MP157DAA1，实物核心板版本、vendor source/DTS/M4 firmware 路径待资料包或板端证据确认。
- K1 平台为 Banana Pi BPI-F3、串口连接，以 TFTP 启动自编译 mainline；板载 Bianbu 可能仍在，bootargs/bootcmd 已修改，精确运行版本待采集。
- 本机有 Clang/LLD 22.1.8、ARM bare-metal GCC 15.2、ARM Linux GNU 15.2.1、RISC-V Linux GNU 15.2.0、DTC 1.8.1 与 dt-schema 2026.6；交叉目标对象 smoke test 已通过，`/opt/arm-gcc-15` 未改动。
- GitHub `origin` 为 `git@github.com:GoKo-Son626/linux_plus.git`，`main` 已建立 upstream；后续完成可解释的小目标即 commit + push。
- 先按现有证据推进；需要卖家资料时给出精确清单，不要求用户一次性整理全部资料。每周持续推进到当周验收真正完成。
- Week 1 二次审计已真实构建 `drivers/remoteproc/stm32_rproc.o`；审计构建不冒充学习者验收。第一周默认由学习者重跑构建，板端固件和恢复路径确认前不执行 sysfs start/stop。
