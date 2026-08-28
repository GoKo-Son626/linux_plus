# 初始实验资料准备总清单

## 结论与交付方式

Week 1 已具备源码、规范、工具链和可构建路径，不等任何卖家资料也能开始。你只需在方便时按 P0 顺序提供；一个批次到一部分，我就先消化一部分。

优先选择以下任一方式：

1. 文件已经在本机或已挂载 Google Drive：只告诉我绝对路径，我负责复制、索引和校验。
2. 需要你下载：保持卖家原始文件名和目录层级，放入以下 Git 忽略目录。

```text
rproc/sources/vendor/user-provided/stm32mp157/
rproc/sources/vendor/user-provided/bpi-f3/
```

大文件、固件、源码压缩包和原始日志不提交 Git；我会把来源、版本、SHA-256、关键路径和审计结论写入 Git。

## P0：有空先给这些

| 平台 | 需要的内容 | 用途 | 推荐文件名 |
|---|---|---|---|
| STM32MP157 | 开发板/核心板正反面照片，丝印可读 | 确认 DAA1/AAA3 与板型 | `board_front.jpg`, `core_both_sides.jpg` |
| STM32MP157 | 从复位到登录 shell 的完整串口文本 | 确认 TF-A/U-Boot/kernel/DT、启动错误 | `stm32_boot_full.log` |
| STM32MP157 | `collect_board_inventory.sh` 的完整输出 | 只读确认 kernel、DT、remoteproc、rpmsg、firmware | `stm32_inventory.txt` |
| STM32MP157 | 正点原子异核通信 PDF 与 `RPMsg_UART_CM4` 完整工程 | 对照卖家 M4/OpenAMP 契约 | 保留原名 |
| BPI-F3 | 当前 TFTP 启动的完整串口日志 | 固定真实 mainline boot flow | `bpi_f3_mainline_boot.log` |
| BPI-F3 | 实际 booted kernel commit、`.config`、Image/DTB 路径 | 把“主线”落到可复现版本 | `git_commit.txt`, `kernel.config` |
| BPI-F3 | U-Boot 中只读执行 `printenv bootargs bootcmd` 的输出，以及你保存的原始 Bianbu 值 | 防止后续调查覆盖可恢复基线 | `uboot_current_env.log`, `uboot_bianbu_saved.txt` |
| BPI-F3 | `collect_board_inventory.sh` 的完整输出 | 确认板端 DT、remoteproc/RPMI 现状 | `bpi_f3_inventory.txt` |

串口日志请提供文本而不是截图；从终端直接保存可搜索内容。暂时找不到 saved bootargs/bootcmd 时只标 `UNKNOWN`，不要凭记忆重写。

## P1：准备做板端 remoteproc 时再给

### STM32MP157

- 正点原子 Linux 5.4.31 kernel tree、板级 DTS/DTSI、defconfig/实际 `.config`。
- 实际使用的 M4 ELF、源码、linker script、resource table 和 OpenAMP 配置。
- `/home/root/shell/rpmsg/M4.sh`、`/lib/firmware/` 相关文件与完整执行日志。
- 当前 TF-A/U-Boot 版本、分区/烧录布局和恢复说明。

### BPI-F3 / K1

- 如能启动 Bianbu：同样收集完整 boot log、`uname -a`、`/etc/os-release`、`/proc/cmdline`、DT model/compatible 和 kernel config。
- 当前 TFTP server 根目录中实际使用的启动脚本、Image、DTB；本地源码仓库绝对路径与 commit。
- 如板上存在 `esos.elf` 或其他 RCPU firmware：只先复制文件和关联日志，不尝试启动。
- 以后准备恢复/重刷时再提供 Bianbu 镜像版本、Titan/烧写工具说明和分区布局。

## P2：进入 bootloader、恢复和深度 vendor 对照时再给

- STM32 的完整 TF-A、U-Boot、Linux、rootfs、Cube/OpenAMP 套件和烧写工具。
- BPI-F3 的完整 BSP、U-Boot、Bianbu image、固件包、原理图和恢复包。
- 全套视频课程只在文字/PDF/源码无法解释具体步骤时按章节补，不整库搬运。

## 不要提供

- SSH 私钥、GitHub token、Google cookie、Wi-Fi 密码、卖家网盘密码等凭据。
- 含隐私的公网 IP、账号或未脱敏配置；局域网地址若用于 TFTP 可保留，也可统一替换为 `<TFTP_SERVER_IP>`。
- 只有成功结尾、没有第一条错误和命令开头的截断日志。

## 我收到后会做什么

1. 计算哈希并记录原始来源、版本与目录。
2. 自动检索 kernel/DTS/firmware/resource table/OpenAMP/rpmsg 关键路径。
3. 区分 `[V]` vendor 资料、`[S]` 固定源码与 `[R]` 板端证据。
4. 只把本周需要的内容加入学习任务；其余建立索引，后续按阶段启用。
