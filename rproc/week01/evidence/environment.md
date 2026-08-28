# Week 01 host environment snapshot

采集时间：2026-08-28。此文件只证明当前 x86_64 学习主机状态，不代表 STM32/K1 板端状态。

- host kernel: `Linux 6.18.46-1-lts x86_64`
- CPU: `AMD Ryzen 7 H 255`, 16 logical CPUs
- Clang: `22.1.8`
- ARM bare-metal GCC: `/opt/arm-gcc-15/.../arm-none-eabi-gcc` (`15.2` toolchain)
- ARM Linux GNU: official Arm `15.2.rel1` archive download/install in progress; existing bare-metal toolchain is preserved
- `riscv64-linux-gnu-gcc`: missing
- `dt-validate` / `dt-doc-validate`: `2026.6`，安装在用户级 Python 3.14 venv；复用系统 `dtc 1.8.1` 提供的 `libfdt`
- `bpftrace`: missing

结论：可立即做源码追踪和 DT schema 校验；GNU 工具链未完成前，内核对象构建可先使用 Clang。bare-metal GCC 不能冒充 ARM Linux kernel GNU cross toolchain。

dt-schema 验证命令与结果：

```text
$ dt-validate --version
2026.6
$ dt-doc-validate --version
2026.6
$ python -c 'import libfdt, dtschema; ...'
/usr/lib/python3.14/site-packages/libfdt.py
2026.6
```
