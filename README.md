# linux-plus

这是个人业余 Linux 学习仓库。当前第一条长期主线是 Linux `remoteproc`（rproc）与 RISC-V RPMI。

## 固定协作方式

- 不创建定时任务。每周一由用户说“上周学完了，安排这周”。
- Codex 先回读仓库状态、上周答案、构建/板端证据和错题，再制定新一周任务。
- Gemini 与 ChatGPT 网页端只提供候选参考；不能替代固定 commit 的源码、Ratified 规范、真实构建或板端日志。
- 每周约 20 小时：工作日每天 2 小时，周末每天 5 小时。
- 优先级固定为：正确性 > 可验证性 > 可持续性 > 动态调整 > 文档观感。

## 当前入口

- 长期记忆与约定：[mem0.md](mem0.md)
- rproc/RPMI 主线：[rproc/README.md](rproc/README.md)
- 第 1 周任务：[rproc/week01/README.md](rproc/week01/README.md)
- 首轮参考资料审计：[rproc/reference-review/2026-08-28-initial-audit.md](rproc/reference-review/2026-08-28-initial-audit.md)
- Week 1 二次审计与真实构建：[rproc/reference-review/2026-08-28-week01-second-audit.md](rproc/reference-review/2026-08-28-week01-second-audit.md)
- 硬件状态矩阵：[rproc/state/hardware_matrix.md](rproc/state/hardware_matrix.md)
- 周度上下文压缩/恢复协议：[rproc/state/WEEKLY_CONTEXT_PROTOCOL.md](rproc/state/WEEKLY_CONTEXT_PROTOCOL.md)
- 厂商资料/源码固定值：[rproc/references/vendor_sources.md](rproc/references/vendor_sources.md)
- 工具链固定值与验证：[rproc/references/toolchains.md](rproc/references/toolchains.md)
- 两块开发板初始资料清单：[rproc/material-requests/initial_lab_preparation.md](rproc/material-requests/initial_lab_preparation.md)

## 证据标签

- `[S]`：固定源码 commit 或 Ratified 规范已核对。
- `[V]`：厂商公开规格、文档或 vendor source 已核对；仍不能替代板端证据。
- `[R]`：本地构建或板端运行已验证，并保存完整证据。
- `[P]`：平台、DTS、固件或 vendor tree 相关，不能泛化。
- `[H]`：尚未验证的假设，必须保留为待办，禁止写成事实。
