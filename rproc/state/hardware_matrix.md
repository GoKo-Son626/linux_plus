# Hardware matrix

未知项保持 `UNKNOWN`，禁止由 AI 猜测填充。

## STM32MP157

- vendor/board family: 正点原子（ALIENTEK）STM32MP157 开发板
- board/revision: `UNKNOWN`（官网标准核心板 `ATK-CLMP157B` 为 `STM32MP157DAA1`；工业核心板 `ATK-CLMP157BI` 为 `STM32MP157AAA3`，需照片或板端信息确认实物）
- access (serial/SSH/local): serial
- bootloader/version: `UNKNOWN`
- vendor baseline: 官网资料包标称 TF-A 2.2、U-Boot 2020.01、Linux 5.4.31；实物当前运行版本 `UNKNOWN`
- kernel repository/commit: 正点原子 vendor source，路径/commit `UNKNOWN`
- active DTS/DTB: `UNKNOWN`
- M4 firmware name/source: `UNKNOWN`
- `/sys/class/remoteproc/`: `UNKNOWN`
- rpmsg/OpenAMP sample: 官网异核通信教程使用 `RPMsg_UART_CM4.elf`、`/home/root/shell/rpmsg/M4.sh` 与 `/dev/ttyRPMSG0`；实物状态 `UNKNOWN`

## SpacemiT K1

- board/revision: Banana Pi BPI-F3，具体 PCB revision `UNKNOWN`
- access (serial/SSH/local): serial
- current boot flow: U-Boot 通过 TFTP 加载自编译 mainline kernel；精确 booted commit/config `UNKNOWN`
- installed distro: 板载存储可能仍有 Bianbu；可重刷，当前版本/是否仍可直接启动 `UNKNOWN`
- U-Boot environment: bootargs/bootcmd 已为 TFTP 修改；原始 Bianbu 值曾保存，位置 `UNKNOWN`
- vendor kernel references: SpacemiT `linux-6.6`、Banana Pi `pi-linux`；板端实际 vendor commit `UNKNOWN`
- RCPU hardware: `[V]` K1 Datasheet V7.1 描述独立 RCPU、256KB RCPU SRAM、256KB Main CPU/RCPU 共享 SRAM 与 Mailbox
- RCPU firmware/source: vendor DTS 默认 `esos.elf`；板端文件/source `UNKNOWN`
- remoteproc/rpmsg runtime: `UNKNOWN`
- RPMI/SBI MPXY runtime: `UNKNOWN`
