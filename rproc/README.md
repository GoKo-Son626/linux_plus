# rproc / RPMI 学习主线

## 目录

- `chatgpt-web/`：用户从 ChatGPT 网页端复制的候选参考包。
- `gemini-spark/`：从 Google Drive 导出的 Gemini 周度产物。
- `reference-review/`：Codex 对外部参考的事实审计。
- `prompts/`：下一周交给外部智能体的定向提示词。
- `references/`：厂商文档、vendor source 与工具链的固定来源/哈希。
- `material-requests/`：需要用户从卖家资料包补充的精确清单。
- `state/`：跨周恢复所需的最小状态。
- `weekNN/`：本周笔记、答案、日志、证据与完成报告。
- `scripts/`：可复现源码准备和验收脚本。
- `sources/`：可重建的外部源码树，已被 Git 忽略。

## 每周开始顺序

1. `state/current_handoff.md` 与 `state/week_state.yaml`
2. 上周 `completion_report.md`
3. 上周错题、源代码追踪、构建/板端日志
4. Git 工作树、最近提交与远端同步状态
5. 本周 ChatGPT/Gemini 参考审计
6. 固定源码/规范复核
7. 生成本周计划、题目与验收门槛

任何 AI 长文都不能越过第 1～3 步直接决定下一周内容。

周末必须先落盘、验收、commit + push，再由用户执行 `/compact`。完整顺序见 [state/WEEKLY_CONTEXT_PROTOCOL.md](state/WEEKLY_CONTEXT_PROTOCOL.md)。

## Week 1

先执行：

```bash
./rproc/scripts/bootstrap_sources.sh
```

然后按 [week01/README.md](week01/README.md) 学习。周末如要做完整内核对象构建，再执行：

```bash
./rproc/scripts/bootstrap_sources.sh --full-linux
```

检查主机工具链与 STM32 binding：

```bash
./rproc/scripts/check_host_tools.sh
```

生成学习者自己的 `stm32_rproc.o` 构建证据：

```bash
./rproc/scripts/build_stm32_rproc_v7_2.sh 2>&1 \
  | tee -a rproc/week01/evidence/build_stm32_rproc.log
```

开发板方便连接时，可在板上只读执行：

```bash
sh collect_board_inventory.sh | tee board_inventory.txt
```

脚本位于 `scripts/collect_board_inventory.sh`，不会启动/停止 remote processor，也不会修改 U-Boot 环境。

需要用户提供的 STM32MP157/BPI-F3 资料按优先级列在 [material-requests/initial_lab_preparation.md](material-requests/initial_lab_preparation.md)。
