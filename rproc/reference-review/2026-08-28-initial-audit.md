# 首周参考资料审计（2026-08-28）

## 结论

- ChatGPT 参考包：可作为 Week 1 的候选事实与教学骨架；版本 pin、remoteproc 调用链、当前 `rproc_ops`、STM32 驱动映射和 Linux RPMI 文件图已与官方源码/规范交叉核对。
- Gemini 两份终版：不适合作为教程。包含多处可直接证伪的接口、协议和运行声明；只保留为“错误样本”和检索线索。
- Week 1 不写 K1 remoteproc 驱动，不写 dummy driver；先掌握 core/ELF/resource table/virtio bridge，并以 STM32MP157 源码和真实构建或板端证据闭环。

## 已核实的 ChatGPT 主结论

1. Linux 版本与 commit pin 和官方远端一致。
2. `rproc_boot()` 先处理 mutex、deleting、power 引用，再走 attach 或 firmware boot。
3. `rproc_fw_boot()` 的主顺序为 sanity -> IOMMU -> prepare -> boot address -> parse -> resources -> carveouts -> `rproc_start()`。
4. `rproc_start()` 先 load segments、同步 resource table、prepare subdevices，再调用平台 `ops->start()`。
5. 当前 `struct rproc_ops` 与 ChatGPT 包列出的成员一致。
6. STM32 `st_rproc_ops` 的通用 ELF helper 与平台回调映射一致。
7. Linux v7.2 已存在 RPMI message header、SBI MPXY mailbox、Clock 与 System-MSI client；固定 master 快照也单独核过。实现数量不能反推规范只含两个 service group。
8. K1 mainline DTS 已出现 `syscon_rcpu` 节点，但 `drivers/remoteproc/` 中未找到对应 K1 remoteproc 平台驱动；因此仍必须做 vendor/mainline 证据矩阵。

## Gemini 中的阻断级错误

| Gemini 声明 | 官方事实 | 处理 |
|---|---|---|
| AMP “提供绝对硬实时确定性” | AMP 只是组织方式；实时性取决于硬件隔离、RTOS、共享资源与最坏时延分析 | 删除绝对化结论 |
| K1 辅核、复位、mailbox、冷热重启均写成已知事实 | 首周材料没有给出可核查 vendor commit/path；mainline 也无 K1 rproc driver | 全部降为 `[H]` |
| boot 时两次 `rproc_handle_resources()` | 固定 master 的 `rproc_fw_boot()` 只在 start 前处理一次 loading resources | 纠正调用链 |
| RPMI 是 32-bit header，Servicegroup 8 bit | RPMI v1.0 是 8-byte header；service group ID 16 bit | 严禁采用 |
| Clock service group ID 为 `0x0005` | v1.0 中 `0x0005` 是 HART_STATE_MANAGEMENT，CLOCK 是 `0x0008` | 严禁采用 |
| 自造 0x0001～0x0009 服务组/操作码表 | v1.0 的正式表为 BASE、SYSTEM_MSI、SYSTEM_RESET、SYSTEM_SUSPEND、HSM、CPPC、VOLTAGE、CLOCK、DEVICE_POWER 等 | 用 Ratified 表替换 |
| Linux RPMI 位于 `drivers/firmware/riscv/`，且已有 reset/regulator/cpufreq 后端 | 当前核实路径为 `drivers/mailbox/riscv-sbi-mpxy-mbox.c`、`drivers/clk/clk-rpmi.c`、`drivers/irqchip/irq-riscv-rpmi-sysmsi.c` 等 | 删除不存在的实现 |
| dummy module `insmod` 后会触发 probe 并出现 sysfs | 代码只注册 `platform_driver`，没有 OF/ACPI 匹配也没有创建 `platform_device`，因此不会自动 probe | 不纳入 Week 1 |
| dummy driver “100% 可编译/可运行” | 文档没有 compiler/config/commit/exit code/object hash/runtime log | 只能标记未验证 |
| 第二次 boot 返回 `-EBUSY` | 当前 `rproc_boot()` 的 power 引用大于 1 时成功返回，不重复物理启动 | 纠正错误码表 |
| rproc 名称重复导致 `rproc_add()` `-EEXIST` | 设备名由唯一 index 形成 `remoteprocN`；该结论无源码证据 | 删除 |
| `dma_alloc_coherent()` 总是把内存设为 uncached/strongly-ordered | 具体一致性与映射属性依架构/平台实现，不能泛化 | 标为平台相关 |
| `no-map` 使内核“完全感知不到”该内存且辅核 SRAM 必须使用 | reserved-memory 仍由内核解析；是否 `no-map` 由 binding/平台决定 | 纠正 |

## 文档视觉审查边界

两份 Gemini Google Docs 已成功导出为有效 DOCX 并完成文本/表格结构提取。当前环境缺少 LibreOffice，无法执行 DOCX -> PNG 的页面级视觉审查；这不影响上述源码/规范事实审计。
