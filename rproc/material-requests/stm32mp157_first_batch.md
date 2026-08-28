# STM32MP157 第一批资料清单

结论：Week 1 的源码学习和 `stm32_rproc.o` 构建已经可以开始，下面资料都不是开课阻断项。方便时按 P0 顺序提供，不需要一次搬完整卖家网盘。

统一交付说明见 [initial_lab_preparation.md](initial_lab_preparation.md)。原始压缩包或目录可放到 Git 忽略的：

```text
rproc/sources/vendor/user-provided/stm32mp157/
```

## P0：最先提供，直接提升第一周实操质量

1. 开发板、核心板正反面清晰照片，重点拍丝印/贴纸；用于确认 `ATK-CLMP157B/BI` 与 `DAA1/AAA3`。
2. 从上电/复位到登录 shell 的完整串口日志，保留 bootloader、kernel、DT model 和错误信息。
3. 板上只读 inventory：运行 `rproc/scripts/collect_board_inventory.sh`，保存完整输出。
4. `〖正点原子〗STM32MP1异核通讯V1.x.pdf` 所在目录。
5. `RPMsg_UART_CM4` 完整工程目录，至少包含 M4 源码、工程配置、linker script 和实际 ELF。

## P1：进入 vendor/mainline 对照与板端启动前提供

1. 卖家 Linux 5.4.31 完整 kernel tree/压缩包，连同板级 DTS/DTSI、defconfig 或实际 `.config`。
2. 包含 `/home/root/shell/rpmsg/M4.sh` 与 `/lib/firmware/` 默认内容的文件；不好拆时再提供 rootfs 压缩包。
3. 当前实际使用的 firmware 文件、烧录布局/分区说明，以及对应 TF-A、U-Boot 版本。
4. 正点原子用户手册、Linux 驱动开发指南中的 M4/OpenAMP/异核通信章节。

## 暂时不需要

- 全部教学视频、所有历史版本镜像和重复网盘包。
- 尚未计划重刷时的整套烧写工具与超大 rootfs 镜像。
- 密码、私钥、Wi-Fi 凭据或公网访问令牌。

材料到齐后由 Codex 搜索路径、生成哈希、建立索引并核验；用户不需要手工解释每个文件。
