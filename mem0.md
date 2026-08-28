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
- 本机有 Clang 22.1.8 和 ARM bare-metal GCC 15.2；缺少 `arm-linux-gnueabihf-gcc`、`riscv64-linux-gnu-gcc`、dt-schema 与 bpftrace。
- STM32MP157/K1 的具体板型、连接方式、当前内核/vendor tree 和固件路径仍待用户确认。
