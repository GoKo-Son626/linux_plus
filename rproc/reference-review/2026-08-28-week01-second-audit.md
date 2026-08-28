# Week 1 二次完整审计（2026-08-28）

## 总结

Week 1 的学习顺序、20h 负荷和技术主链可执行，没有需要推翻的结构性问题。二次审计修复了评分不可执行、主机依赖漏检、RPMI transport 表述过窄、板端写操作门槛不够明确四类问题，并完成一次独立真实对象构建。

最终判断：Week 1 可在 2026-08-31 开始；STM32/K1 vendor 材料未知不会阻断源码学习和对象构建。

## 技术正确性复核

| 主题 | 固定证据 | 结论 |
|---|---|---|
| boot 主链 | Linux v7.2 `remoteproc_core.c` | `rproc_boot()` 管 lock/state/power 和 attach/firmware 分支；firmware 分支进入 `rproc_fw_boot()` |
| firmware boot | Linux v7.2 `rproc_fw_boot()` | sanity → IOMMU → prepare → bootaddr → parse → resources → carveouts → `rproc_start()` |
| 真正 start 前顺序 | Linux v7.2 `rproc_start()` | load segments → 同步 loaded resource table → prepare subdevices → `ops->start()` → start subdevices → RUNNING |
| STM32 映射 | Linux v7.2 `stm32_rproc.c` | `prepare/start/stop/attach/detach/kick` 为平台回调；ELF sanity/load/bootaddr/find table 复用 generic helper |
| RPMI 五个抽象 | RPMI v1.0 `src/intro.adoc` | Transport、Messaging Protocol、Service Groups、Client、Context，确为规范正式分类 |
| RPMI header | RPMI v1.0 `src/message-protocol.adoc` | 固定 8 bytes；FLAGS 8b、SERVICE_ID 8b、SERVICEGROUP_ID 16b、TOKEN 16b、DATALEN 16b |
| RPMI service groups | RPMI v1.0 `src/service-groups.adoc` | BASE 必选，其余可选；v1.0 标准表包含 0x0001～0x000D，不可由 Linux 已实现 client 数量反推规范范围 |
| Linux RPMI 路径 | Linux v7.2 | message header、shared-memory/SBI MPXY bindings、`clk-rpmi.c`、`riscv-sbi-mpxy-mbox.c`、`irq-riscv-rpmi-sysmsi.c` 均已存在 |

## 学习与验收修正

1. 保留“RPMI 五个抽象”，但在任务中写出五个正式名称和规范文件锚点。
2. 明确 RPMI v1.0 定义 direct shared-memory transport；SBI MPXY 是代理/虚拟化路径，不是所有请求必经层。Linux v7.2 虽有两类 DT bindings，但本地源码只确认到 SBI MPXY mailbox driver，不能把 binding 当成 direct driver 已实现。
3. 周测改为精确的 30 + 40 + 30 权重，并增加阻断级错误门禁与 Codex 复核位。
4. runtime inventory 与 sysfs start/stop 分离；固件、状态、日志和恢复方式未知时，禁止用板端写操作代替安全的对象构建。
5. `check_host_tools.sh` 补充内核对象构建真正需要的 `bc` 等 host tools；当周验收脚本验证 section sum、阻断错误和结构化 build metadata。
6. `collect_board_inventory.sh` 移除 GNU `find -printf`，改为 BusyBox 更易支持的 shell glob、`readlink` 与 `find -print`。
7. 构建日志改为追加保存并只接受最后一次 run 的 PASS；预填 K1 矩阵增加学习者复核门槛；完成报告只记录真实误解，不强迫凑三条错误。

## 独立构建证据

第一次真实构建在生成 `include/generated/timeconst.h` 时失败：`bc: 未找到命令`，exit 2。随后从 Arch 官方镜像获取签名包 `bc 1.08.2-1`，验证签名后仅解出到用户目录，未修改 `/opt/arm-gcc-15`。

第二次构建：

```text
Linux: v7.2 / 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
ARCH: arm
CROSS_COMPILE: arm-none-linux-gnueabihf-
compiler: Arm GNU Toolchain 15.2.1
config: CONFIG_ARCH_STM32=y, CONFIG_REMOTEPROC=y, CONFIG_STM32_RPROC=y
target: drivers/remoteproc/stm32_rproc.o
exit: 0
file: ELF 32-bit LSB relocatable, ARM, EABI5, debug_info, not stripped
sha256: 26ebb19a75db73c7c2cdc4109e947d3becf413f1a3ce8b153a57d0519d51ab82
```

构建目录在 Git 忽略的 `rproc/build/audit-stm32-v7.2/`。这份证据证明任务设计可落地，不计入学习者 Week 1 验收；学习者仍需运行仓库脚本生成自己的日志。

## 仍保持 UNKNOWN

- STM32MP157 实物核心板具体料号、当前 DTS、M4 firmware、vendor runtime。
- BPI-F3 当前 booted mainline commit/config、Bianbu 状态、RCPU/RPMI runtime。
- Gemini DOCX 的页面级视觉排版未重新渲染；本轮重点是学习内容、源码、规范、脚本与验收逻辑。

这些未知项已移到 `pending_inputs`，不再误标为 Week 1 blocker。
