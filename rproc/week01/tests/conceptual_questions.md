# Week 01 闭卷测试

先将答案写到 `conceptual_answers.md`，再查看 ChatGPT 参考包中的判定要点。

## A. 核心概念（10 x 4）

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

## B. 源码追踪（8 x 5）

11. 从 sysfs `echo start > state` 写到 `rproc_boot()` 的关系是什么？
12. resource handling 位于平台 `ops->start()` 之前还是之后？为什么？
13. `rproc_start()` 为什么在 `ops->start()` 前加载 ELF segments？
14. STM32 `dma-ranges`/translation 在驱动中解决什么问题？
15. `vq0/vq1` mailbox 与 vring 分别承担什么角色？
16. 为什么旧版 `remoteproc.rst` 不能代替当前 `remoteproc.h`？
17. RPMI v1.0 message header 的总长度和字段是什么？
18. `clk-rpmi.c` 为什么走 mailbox abstraction 而不内嵌 MPXY 细节？

## C. 判断并解释（20 分）

19. 有 RPMI 后就不需要 remoteproc。
20. 所有 remote processor 都必须由 Linux 加载并启动。
21. mailbox 保存 rpmsg payload。
22. Resource Table 只能描述内存。
23. RPMI GitHub `main` 比 v1.0 新，所以规范学习应以 `main` 为准。
24. Linux 当前只有 Clock/System-MSI client，说明规范也只有两个 service group。
25. K1 mainline DTS 中有 `syscon_rcpu` 就等于主线已有可运行 remoteproc driver。
