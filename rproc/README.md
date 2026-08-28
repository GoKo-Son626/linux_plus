# rproc / RPMI 学习主线

## 目录

- `chatgpt-web/`：用户从 ChatGPT 网页端复制的候选参考包。
- `gemini-spark/`：从 Google Drive 导出的 Gemini 周度产物。
- `reference-review/`：Codex 对外部参考的事实审计。
- `prompts/`：下一周交给外部智能体的定向提示词。
- `state/`：跨周恢复所需的最小状态。
- `weekNN/`：本周笔记、答案、日志、证据与完成报告。
- `scripts/`：可复现源码准备和验收脚本。
- `sources/`：可重建的外部源码树，已被 Git 忽略。

## 每周开始顺序

1. `state/week_state.yaml`
2. 上周 `completion_report.md`
3. 上周错题、源代码追踪、构建/板端日志
4. 本周 ChatGPT/Gemini 参考审计
5. 固定源码/规范复核
6. 生成本周计划、题目与验收门槛

任何 AI 长文都不能越过第 1～3 步直接决定下一周内容。

## Week 1

先执行：

```bash
./rproc/scripts/bootstrap_sources.sh
```

然后按 [week01/README.md](week01/README.md) 学习。周末如要做完整内核对象构建，再执行：

```bash
./rproc/scripts/bootstrap_sources.sh --full-linux
```
