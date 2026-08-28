# SpacemiT K1 vendor/mainline evidence matrix

| 问题 | Mainline 固定 commit | Vendor/官方资料 | 板端 `[R]` | 当前结论 |
|---|---|---|---|---|
| RCPU 硬件实体 | `k1.dtsi` 有 `syscon_rcpu`/`syscon_rcpu2` | `TODO` | `UNKNOWN` | `[S]` mainline 描述了相关 syscon；核契约仍待查 |
| remoteproc driver | `drivers/remoteproc/` 未找到 K1 platform driver | `TODO` | `UNKNOWN` | `[S]` 当前 mainline 无已核实 K1 rproc driver |
| boot/reset | `TODO` | `TODO` | `UNKNOWN` | `[H]` |
| mailbox/doorbell | `TODO` | `TODO` | `UNKNOWN` | `[H]` |
| reserved/shared memory | `TODO` | `TODO` | `UNKNOWN` | `[H]` |
| Resource Table | `TODO` | `TODO` | `UNKNOWN` | `[H]` |
| rpmsg runtime | generic framework exists | `TODO` | `UNKNOWN` | `[H]` K1 是否接通 |
| RPMI/SBI MPXY | generic Linux implementation exists | `TODO` | `UNKNOWN` | `[H]` K1 是否启用 |
