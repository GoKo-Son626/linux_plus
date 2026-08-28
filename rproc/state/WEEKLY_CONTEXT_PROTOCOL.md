# 周度上下文交接与压缩协议

## 最佳做法

每周只在一个明确里程碑后压缩：本周验收完成、状态已落盘、Git 已提交并推送之后。不要在源码追踪、编译失败定位或板端实验进行到一半时执行 `/compact`。

当前 Codex CLI 0.150.1 在界面中支持用户执行 `/compact`；当前代理没有可安全代替用户触发该界面命令的工具。系统也可能在上下文接近上限时自动压缩。无论哪种情况，连续性都必须来自仓库和 Mem0，而不是依赖聊天全文。

OpenAI 的长任务指导建议在重大里程碑后有意压缩，并在交接中保留已完成动作、仍有效假设、工具结果、未解决 blocker 和下一个具体目标：

- <https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.5>
- <https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.2>

## 每周结束顺序

1. 完成本周题目、源码追踪、构建/板端证据和 `completion_report.md`。
2. Codex 人工评分并更新 `tests/weekNN_score.yaml`、`state/misconceptions.md` 和 `state/week_state.yaml`。
3. Codex 更新 `state/current_handoff.md`：完成项、有效 source pins、未知项、blocker、下一周第一步。
4. 运行当周检查脚本；失败就继续修正，不进入压缩。
5. Codex commit + push，并确认工作树干净、`main` 与 `origin/main` 同步。
6. Codex 明确告诉用户：“检查点已落盘并推送，现在可以 `/compact`。”
7. 用户执行一次 `/compact`。如果本轮刚发生过自动压缩，则不必立刻重复压缩。

## 下周恢复顺序

用户只需说：

```text
第 X 周开始；上周已经完成并按检查点压缩，请回读状态后安排本周。
```

Codex 必须按以下顺序恢复：

1. `mem0.md` 与 Mem0 项目记忆。
2. `state/current_handoff.md`、`state/week_state.yaml`、`state/source_pins.md`、`state/hardware_matrix.md`。
3. 上周 `completion_report.md`、score、错题和真实 evidence。
4. `git log -n 5`、`git status`、远端同步状态。
5. 新一周 Gemini/ChatGPT 候选资料；只能在前四步后参与计划。

## 什么时候不要压缩

- 还有未保存的串口输出、命令、错误信息或用户答案。
- 工作树有尚未解释/提交的改动。
- 正在定位一个跨多轮错误，且 `current_handoff.md` 尚未记录已排除项。
- Codex 尚未明确给出 safe-to-compact 状态。

## 长周期控制

每周最多主动压缩一次。每 4 周或每个阶段里程碑结束时，可直接新建会话，再依靠同一恢复顺序接力；这比在一个超长会话里反复多次压缩更稳。整体规划固定在 Git 和 Mem0 中，因此新会话不会丢掉主线。
