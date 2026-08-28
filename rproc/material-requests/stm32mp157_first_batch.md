# STM32MP157 第一批资料清单

第一周不需要把卖家网盘全部搬过来。优先下载并放到本仓库后续约定的 vendor 资料目录，保留原始目录层级和压缩包文件名。

## P0：第一周直接使用

1. `〖正点原子〗STM32MP1异核通讯V1.x.pdf` 所在的完整上级目录。
2. `RPMsg_UART_CM4` 示例的完整工程目录，至少包含 M4 源码、工程配置、linker script 和 `RPMsg_UART_CM4.elf`。
3. 卖家 Linux 5.4.31 源码压缩包，或已解压的完整 kernel tree；同时带上正点原子板级 DTS/DTSI 和实际使用的 defconfig/`.config`。
4. 包含 `/home/root/shell/rpmsg/M4.sh` 与 `/lib/firmware/` 默认内容的 rootfs 文件包；如果不好拆，直接提供卖家 rootfs 压缩包。
5. 开发板核心板正反面清晰照片，重点拍到丝印/贴纸；用于确认 `ATK-CLMP157B/BI` 与 `DAA1/AAA3`。

## P1：后续烧录与恢复需要

- 对应版本 TF-A、U-Boot、Linux、rootfs 的完整源码/镜像与烧写工具说明。
- 正点原子完整用户手册、Linux 驱动开发指南、M4/OpenAMP 相关章节。
- 当前实际使用的烧录布局/分区说明。

## 板端只读信息

板子方便连接后，将 `rproc/scripts/collect_board_inventory.sh` 复制到板上直接运行，把完整输出保存到 `rproc/week01/evidence/stm32_inventory.txt`。脚本不启动/停止 M4，不写 U-Boot 环境，不要求修改系统。

这些材料到齐后，Codex 负责自行搜索路径、建立索引和逐项核验；用户不需要手工解释每个文件。
