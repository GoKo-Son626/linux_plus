#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rproc_dir="$(cd "${script_dir}/.." && pwd)"
source_dir="${rproc_dir}/sources"
linux_dir="${source_dir}/linux-v7.2"
rpmi_dir="${source_dir}/rpmi-v1.0"
linux_commit="8d3ae59288f1e7d58d76558a6ee96d533bc5019f"
rpmi_commit="27db4b4a405af971f84999adad4806d291f1338e"
full_linux=false

if [[ "${1:-}" == "--full-linux" ]]; then
    full_linux=true
elif [[ -n "${1:-}" ]]; then
    echo "usage: $0 [--full-linux]" >&2
    exit 2
fi

mkdir -p "${source_dir}"

if [[ ! -d "${linux_dir}/.git" ]]; then
    git clone --depth=1 --branch v7.2 --filter=blob:none --sparse \
        https://github.com/torvalds/linux.git \
        "${linux_dir}"
    git -C "${linux_dir}" sparse-checkout set \
        arch/arm arch/riscv/boot/dts/spacemit \
        include drivers/remoteproc drivers/rpmsg drivers/mailbox \
        drivers/clk drivers/irqchip Documentation/staging \
        Documentation/devicetree/bindings/remoteproc \
        Documentation/devicetree/bindings/mailbox \
        Documentation/devicetree/bindings/clock \
        Documentation/devicetree/bindings/interrupt-controller
fi

actual_linux_commit="$(git -C "${linux_dir}" rev-parse HEAD)"
if [[ "${actual_linux_commit}" != "${linux_commit}" ]]; then
    echo "Linux pin mismatch: ${actual_linux_commit}" >&2
    exit 1
fi

if [[ "${full_linux}" == true ]]; then
    git -C "${linux_dir}" sparse-checkout disable
fi

if [[ ! -d "${rpmi_dir}/.git" ]]; then
    git clone --depth=1 --branch v1.0 \
        https://github.com/riscv-non-isa/riscv-rpmi.git "${rpmi_dir}"
fi

actual_rpmi_commit="$(git -C "${rpmi_dir}" rev-parse HEAD)"
if [[ "${actual_rpmi_commit}" != "${rpmi_commit}" ]]; then
    echo "RPMI pin mismatch: ${actual_rpmi_commit}" >&2
    exit 1
fi

echo "Linux: ${linux_dir} @ ${actual_linux_commit}"
echo "RPMI:  ${rpmi_dir} @ ${actual_rpmi_commit}"
