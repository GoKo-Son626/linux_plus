# Vendor source and document pins

核验时间：2026-08-28（Asia/Shanghai）。大体积资料保存在 Git 忽略的 `rproc/sources/vendor/`；本文件保存来源、固定值和校验值。

## 正点原子 STM32MP157

| 项目 | 官方来源 | 当前用途 |
|---|---|---|
| 核心板型号 | <https://wiki.alientek.com/docs/Boards/Linux/STM32MP157/STM32MP157%20%E6%A0%B8%E5%BF%83%E6%9D%BF%E8%A7%84%E6%A0%BC%E4%B9%A6/1/1.1/> | 标准 `ATK-CLMP157B` = `STM32MP157DAA1`；工业 `ATK-CLMP157BI` = `STM32MP157AAA3` |
| 软件资源 | <https://wiki.alientek.com/docs/Boards/Linux/STM32MP157/STM32MP157%26Mini%20%E7%A1%AC%E4%BB%B6%E5%8F%82%E8%80%83%E6%89%8B%E5%86%8C/2/1.2.2/> | 厂商资料基线 Linux 5.4.31、U-Boot 2020.01、M4 示例 |
| 异核通信示例 | <https://wiki.alientek.com/docs/Boards/Linux/STM32MP157/STM32MP157%20%E5%BF%AB%E9%80%9F%E4%BD%93%E9%AA%8C%E6%89%8B%E5%86%8C/4/4.30/> | 定位教程、`RPMsg_UART_CM4.elf`、`M4.sh`、`ttyRPMSG0` |

厂商页面只能证明官方资料包的默认方案，不能证明用户实物当前烧录内容。

## SpacemiT K1 / Banana Pi BPI-F3

| 对象 | 固定值/版本 | 官方来源 |
|---|---|---|
| K1 Datasheet PDF | V7.1，2026-07-14；158 pages | <https://cdn-resource.spacemit.com/file/chip/K1/K1_datasheet_en.pdf> |
| K1 Datasheet PDF SHA-256 | `18975daeb9c036f6320a207fddc7f184bd13e4945ef3c5e6f6ad304372e3bf89` | 本地 `rproc/sources/vendor/spacemit-k1/K1_datasheet_en_V7.1.pdf` |
| K1 Datasheet Markdown | `docs-chip@59e2545d620986d5a960b1ad51339903fb37eec5` | <https://github.com/spacemit-com/docs-chip/blob/59e2545d620986d5a960b1ad51339903fb37eec5/en/key_stone/k1/k1_docs/k1_ds.md> |
| SpacemiT vendor kernel | `linux-6.6` branch `k1-bl-v2.2.y` @ `31c449aeaad8c7759bc983ca0e26946e5b6746dc` | <https://github.com/spacemit-com/linux-6.6/tree/31c449aeaad8c7759bc983ca0e26946e5b6746dc> |
| Banana Pi BSP kernel | `pi-linux` branch `linux-6.6.63-k1` @ `fee24f3ca7f6c028784bbb631024d57d97c99d0d` | <https://github.com/BPI-SINOVOIP/pi-linux/tree/fee24f3ca7f6c028784bbb631024d57d97c99d0d> |
| Banana Pi BSP U-Boot | `pi-u-boot` branch `v2022.10-k1` @ `cdddb8e05f3a348bd2e847e85ba622f29c966a88` | <https://github.com/BPI-SINOVOIP/pi-u-boot/tree/cdddb8e05f3a348bd2e847e85ba622f29c966a88> |
| BPI-F3 board page | rolling page，运行版本需板端确认 | <https://wiki.banana-pi.org/Banana_Pi_BPI-F3> |

### 已采集的 K1 vendor 源码切片

来源均为 `spacemit-com/linux-6.6@31c449aeaad8c7759bc983ca0e26946e5b6746dc`：

| 文件 | SHA-256 |
|---|---|
| `drivers/remoteproc/spacemit/k1x-rproc.c` | `cff209bdda2671d9cc45bb1dbf8aa72ed8371d24ba280267d2203bdab814afd5` |
| `drivers/remoteproc/spacemit/Makefile` | `4b5d6bf76afe66a870c64a40e8832cd9b0b1fff5b917fbb4aeca69585a7e7cd7` |
| `drivers/mailbox/spacemit/k1x-mailbox.c` | `36bd2cbacea52ad51ec755b889cb01aaac47109e4a2eb3b460a95aaa51daf8fe` |
| `drivers/mailbox/spacemit/k1x_mailbox.h` | `20a0c6a8aff032d8a89239de9a1119f4cf9fcdd572e802f0e628afdd76969566` |
| `drivers/mailbox/spacemit/Makefile` | `69eff19e761dc4091adfec6b3dcd95d41b22f056fca8893fbe4163b17b457e20` |
| `arch/riscv/boot/dts/spacemit/k1-x.dtsi` | `60e282c66f65170199a4ad54ff873918dfa1088a7dc2b6c9607ee91efae2c154` |

重新核验：

```bash
git ls-remote https://github.com/spacemit-com/docs-chip.git refs/heads/main
git ls-remote https://github.com/spacemit-com/linux-6.6.git refs/heads/k1-bl-v2.2.y
git ls-remote https://github.com/BPI-SINOVOIP/pi-linux.git refs/heads/linux-6.6.63-k1
git ls-remote https://github.com/BPI-SINOVOIP/pi-u-boot.git refs/heads/v2022.10-k1
find rproc/sources/vendor/spacemit-linux-6.6 -type f -print0 | sort -z | xargs -0 sha256sum
```

`Bianbu 基于 Linux 6.6` 只能作为候选线索：上表证明厂商存在 6.6 分支，不证明板内当前镜像版本。必须以 `uname -a`、DT model/compatible 和启动日志为准。
