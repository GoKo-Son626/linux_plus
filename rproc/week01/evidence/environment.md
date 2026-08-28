# Week 01 host environment snapshot

采集时间：2026-08-28。此文件只证明当前 x86_64 学习主机状态，不代表 STM32/K1 板端状态。

- host kernel: `Linux 6.18.46-1-lts x86_64`
- CPU: `AMD Ryzen 7 H 255`, 16 logical CPUs
- Clang: `22.1.8`
- ARM bare-metal GCC: `/opt/arm-gcc-15/.../arm-none-eabi-gcc` (`15.2` toolchain)
- ARM Linux GNU: `arm-none-linux-gnueabihf-gcc 15.2.1`，用户级安装；target `arm-none-linux-gnueabihf`
- RISC-V Linux GNU: Arch package `riscv64-linux-gnu-gcc 15.2.0-1`；target `riscv64-linux-gnu`
- LLD: `22.1.8`
- DTC: `1.8.1`
- `dt-validate` / `dt-doc-validate`: `2026.6`，安装在用户级 Python 3.14 venv；复用系统 `dtc 1.8.1` 提供的 `libfdt`
- `bpftrace`: missing

结论：Week 1 所需源码追踪、ARM/RISC-V GNU/LLVM 编译与 DT schema 校验环境已就绪。`/opt/arm-gcc-15` 的 bare-metal GCC 未被移动或覆盖，仍不能冒充 ARM Linux kernel GNU cross toolchain。

dt-schema 验证命令与结果：

```text
$ dt-validate --version
2026.6
$ dt-doc-validate --version
2026.6
$ python -c 'import libfdt, dtschema; ...'
/usr/lib/python3.14/site-packages/libfdt.py
2026.6
$ dt-doc-validate rproc/sources/linux-v7.2/Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml
# exit 0, no diagnostics
```

交叉编译器 smoke test：

```text
$ printf 'int probe(void) { return 42; }' | arm-none-linux-gnueabihf-gcc -x c -c -o arm.o -
arm.o: ELF 32-bit LSB relocatable, ARM, EABI5

$ printf 'int probe(void) { return 42; }' | riscv64-linux-gnu-gcc -x c -c -o riscv.o -
riscv.o: ELF 64-bit LSB relocatable, UCB RISC-V, RVC, double-float ABI
```

下载来源、包签名与 SHA-256 见 `rproc/references/toolchains.md`。
