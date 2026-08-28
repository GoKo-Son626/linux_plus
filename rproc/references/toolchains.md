# Toolchain pins and verification

核验时间：2026-08-28（Asia/Shanghai）。工具链不进入学习仓库 Git；本文件记录来源、版本、安装边界和真实验证结果。

## ARM Linux GNU

- source: Arm GNU Toolchain official binary release
- archive: `arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz`
- official URL: <https://developer.arm.com/-/media/Files/downloads/gnu/15.2.rel1/binrel/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz>
- SHA-256: `3c65d820a6b8f677f8f6fbfc749fe00a4f16dde12341436c9df5b7092a47c0fb`，与 Arm 官方 `.sha256asc` 内容一致
- install root: `/home/shuqi/.local/opt/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-linux-gnueabihf`
- command exposure: `~/.local/bin/arm-none-linux-gnueabihf-*` symlink
- version: `arm-none-linux-gnueabihf-gcc 15.2.1 20251203`
- target/sysroot: `arm-none-linux-gnueabihf`；工具链自带 sysroot
- smoke result: ELF32 little-endian ARM, EABI5 relocatable object

既有 `/opt/arm-gcc-15/arm-gnu-toolchain-15.2.rel1-x86_64-arm-none-eabi` 未移动、未覆盖、未删改。

## RISC-V Linux GNU

本机 pacman sync database 仍指向已从普通镜像轮换掉的 15.1.0 包，因此第一次 `pacman -S` 在下载阶段持续得到 404 并被中止。随后从中科大 Arch 镜像下载 Arch 官方 2026-08-27/28 当前包，先逐包执行 `pacman-key --verify`，再用 `pacman -U` 一次升级四个交叉包；事务报告旧版本为 GCC 15.1.0、binutils 2.44、glibc 2.41、headers 6.10，没有执行系统全量升级。

| Package | Version | SHA-256 |
|---|---|---|
| `riscv64-linux-gnu-gcc` | `15.2.0-1` | `694934ee076327df5d64405aba7b57365eab6ea747dc31f9bd27ebf64bc02fb1` |
| `riscv64-linux-gnu-binutils` | `2.45.1-1` | `e4edb892a4267fd05c232c1dd333762bc0d5a0cd1181b0e261eee321c7ec0f28` |
| `riscv64-linux-gnu-glibc` | `2.43-1` | `860c76398210f18cc903cd2e7a86aa8fe0446538d56edfa3da542b3eae3f4304` |
| `riscv64-linux-gnu-linux-api-headers` | `6.14-1` | `9652f9558f7ee5508651ecc42b4a9e7d3e29b11cf18dd44f4178a596f789921a` |

- Arch official package: <https://archlinux.org/packages/extra/x86_64/riscv64-linux-gnu-gcc/>
- mirror path: <https://mirrors.ustc.edu.cn/archlinux/extra/os/x86_64/>
- signatures: GCC/binutils/glibc verified against trusted Arch key `B5971F2C5C10A9A08C60030F786C63F330D7CB92`; headers verified against trusted Arch key `C5D2A6E0ED2D11C66B9FA2A306313911057DD5A8`
- target/sysroot: `riscv64-linux-gnu`；`/usr/riscv64-linux-gnu`
- smoke result: ELF64 little-endian RISC-V, RVC, double-float ABI relocatable object

## LLVM, DTC and dt-schema

| Tool | Version | Verification |
|---|---|---|
| Clang | `22.1.8` | `clang --version` |
| LLD | `22.1.8` | `ld.lld --version` |
| DTC | `1.8.1` | `dtc --version` |
| dt-schema | `2026.6` | `dt-validate --version` and `dt-doc-validate --version` |

dt-schema 使用 `/home/shuqi/.local/share/linux-plus/dtschema-2026.6` Python 3.14 venv；复用 `dtc` 包提供的 `/usr/lib/python3.14/site-packages/libfdt.py`。实际执行：

```bash
dt-doc-validate \
  rproc/sources/linux-v7.2/Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml
```

结果为 exit 0 且无诊断。

## bc host build dependency

- package: Arch `bc 1.08.2-1` (`x86_64`)
- mirror: <https://mirrors.ustc.edu.cn/archlinux/extra/os/x86_64/bc-1.08.2-1-x86_64.pkg.tar.zst>
- SHA-256: `b9e5f0d61a674c9be1a0608f3fcab766d989d9a002c37e55a74ccfc8e87027ab`
- signature: Arch packager key `E75CD4814A77AD943C7AB5A3E0959FEA8B550539`，`pacman-key --verify` 为 Good signature
- install boundary: 系统包未改动；只把 `bc`/`dc` 从已验证包解到 `/home/shuqi/.local/bin/`
- version: `bc 1.08.2`
- reason: Linux v7.2 ARM object build生成 `include/generated/timeconst.h` 时真实需要；缺失时构建以 exit 2 停止
