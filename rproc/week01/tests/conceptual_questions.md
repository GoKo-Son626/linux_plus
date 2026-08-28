# Week 01 闭卷测试

先将答案写到 `conceptual_answers.md`，再查看 ChatGPT 参考包中的判定要点。

## 计分规则

- A：10 题，每题 3 分，共 30 分。
- B：8 题，每题 5 分，共 40 分。
- C：第 19～23 题每题 4 分，第 24～25 题每题 5 分，共 30 分。
- 总分 100。事实结论、源码顺序和理由分别给分；只有结论、没有理由，单题最多得一半。
- 以下任一项属于阻断级错误：把 RPMI 与 remoteproc 视为替代关系；把 payload 写进 mailbox；把 DA/PA/VA 说成必然相等；把 `ops->start()` 放到 firmware segment/resource 准备之前；使用错误的 RPMI header 宽度或 service-group ID。存在阻断错误时即使总分达到 80，也必须纠正并重测。

## A. 核心概念（30 分）

1. remoteproc 与 rpmsg 的职责边界是什么？
2. 为什么 `rproc_boot()` 不等于直接调用 `ops->start()`？
3. `rproc->power` 解决什么问题？
4. `RPROC_DETACHED` 时为什么可能不加载 firmware？
5. Resource Table 与 Device Tree 的视角有何不同？
6. DA、AP bus/PA 与 Linux VA 是否保证相等？
7. `RSC_VDEV` 如何把 remoteproc 接到 virtio/rpmsg？
8. payload 已写入共享 buffer 后为什么仍需要 `kick()`？
9. STM32 驱动复用了哪些 generic ELF helper？至少两个。
10. RPMI 与 remoteproc 为什么不是替代关系？

## B. 源码追踪（40 分）

11. 从 sysfs `echo start > state` 写到 `rproc_boot()` 的关系是什么？
12. resource handling 位于平台 `ops->start()` 之前还是之后？为什么？
13. `rproc_start()` 为什么在 `ops->start()` 前加载 ELF segments？
14. STM32 `dma-ranges`/translation 在驱动中解决什么问题？
15. `vq0/vq1` mailbox 与 vring 分别承担什么角色？
16. 为什么旧版 `remoteproc.rst` 不能代替当前 `remoteproc.h`？
17. RPMI v1.0 message header 的总长度和字段是什么？
18. `clk-rpmi.c` 为什么走 mailbox abstraction 而不内嵌 MPXY 细节？

## C. 判断并解释（30 分）

19. 有 RPMI 后就不需要 remoteproc。
20. 所有 remote processor 都必须由 Linux 加载并启动。
21. mailbox 保存 rpmsg payload。
22. Resource Table 只能描述内存。
23. RPMI GitHub `main` 比 v1.0 新，所以规范学习应以 `main` 为准。
24. Linux 当前只有 Clock/System-MSI client，说明规范也只有两个 service group。
25. K1 mainline DTS 中有 `syscon_rcpu` 就等于主线已有可运行 remoteproc driver。
