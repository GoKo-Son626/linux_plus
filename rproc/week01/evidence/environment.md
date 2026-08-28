# Week 01 host environment snapshot

采集时间：2026-08-28。此文件只证明当前 x86_64 学习主机状态，不代表 STM32/K1 板端状态。

- host kernel: `Linux 6.18.46-1-lts x86_64`
- CPU: `AMD Ryzen 7 H 255`, 16 logical CPUs
- Clang: `22.1.8`
- ARM bare-metal GCC: `/opt/arm-gcc-15/.../arm-none-eabi-gcc` (`15.2` toolchain)
- `arm-linux-gnueabihf-gcc`: missing
- `riscv64-linux-gnu-gcc`: missing
- `dt-validate` / `dt-doc-validate`: missing
- `bpftrace`: missing

结论：可立即做源码追踪；内核 ARM 对象构建先尝试 Clang，失败则记录缺失依赖。bare-metal GCC 不能冒充 ARM Linux kernel GNU cross toolchain。
