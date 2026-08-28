# SpacemiT K1 vendor/mainline evidence matrix

| 问题 | Mainline 固定 commit | Vendor/官方资料 | 板端 `[R]` | 当前结论 |
|---|---|---|---|---|
| RCPU 硬件实体 | `k1.dtsi` 有 `syscon_rcpu`/`syscon_rcpu2` | K1 Datasheet V7.1：独立 RCPU、256KB RCPU SRAM、256KB Main CPU/RCPU 共享 SRAM | `UNKNOWN` | `[V][S]` 硬件实体已确认；主线当前只描述相关 syscon |
| remoteproc driver | `drivers/remoteproc/` 未找到 K1 platform driver | SpacemiT `linux-6.6@31c449ae` 有 `k1x-rproc.c`，compatible 为 `spacemit,k1-x-rproc` | `UNKNOWN` | `[S]` vendor 有实现，Linux v7.2 主线无对应 platform driver |
| boot/reset | 主线无 K1 rproc ops | vendor driver 注册 `.start/.stop`；具体寄存器和时序留到 Week 1 逐行追踪 | `UNKNOWN` | `[S]` 存在 vendor 实现；尚未证明板端可启动 |
| mailbox/doorbell | 主线未找到 K1 mailbox driver | Datasheet V7.1 2.9.6；vendor `k1x-mailbox.c` 与 DTS `spacemit,k1-x-mailbox` | `UNKNOWN` | `[V][S]` 硬件与 vendor driver 已确认，主线缺口明确 |
| reserved/shared memory | 主线无 RCPU remoteproc 节点 | vendor `k1-x.dtsi` 定义 RCPU code/heap/vring/buffer/rsc_table，driver 迭代 `memory-region` 建 carveout | `UNKNOWN` | `[S]` vendor 内存契约可追踪；实物地址与 DTB 尚未验证 |
| Resource Table | 无 K1 特化实现 | vendor DTS 有 `rsc_table` 区域，driver 有自定义 firmware/resource-table 处理 | `UNKNOWN` | `[S]` 源码路径已定位；`esos.elf` 的实际表内容仍未知 |
| rpmsg runtime | generic remoteproc/virtio/rpmsg framework exists | vendor driver `.kick` 使用 mailbox，回调进入 `rproc_vq_interrupt()`；DTS 默认 firmware `esos.elf` | `UNKNOWN` | `[S]` 接线设计存在；板端 rpmsg endpoint 未证明 |
| RPMI/SBI MPXY | generic Linux implementation exists | K1 remoteproc/vendor 代码本身不能证明 RPMI | `UNKNOWN` | `[H]` K1 是否启用 RPMI/MPXY 保持未知 |

证据固定值与文件哈希见 `rproc/references/vendor_sources.md`。`[V]` 表示厂商公开资料，`[S]` 表示固定源码，`[R]` 表示真实板端证据，`[H]` 表示待验证假设。
