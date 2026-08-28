#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rproc_dir="$(cd "${script_dir}/.." && pwd)"
repo_dir="$(cd "${rproc_dir}/.." && pwd)"
linux_dir="${rproc_dir}/sources/linux-v7.2"
output_dir="${rproc_dir}/build/week01-stm32-v7.2"
expected_commit="8d3ae59288f1e7d58d76558a6ee96d533bc5019f"
cross_compile="arm-none-linux-gnueabihf-"

report_result()
{
    local exit_code=$?
    printf 'exit_code: %d\n' "${exit_code}"
    if (( exit_code == 0 )); then
        printf 'result: PASS\n'
    else
        printf 'result: FAIL\n'
    fi
}
trap report_result EXIT

printf 'run_started_at: %s\n' "$(date -Iseconds)"

for required_tool in bc make sha256sum "${cross_compile}gcc"; do
    if ! command -v "${required_tool}" >/dev/null 2>&1; then
        printf 'missing required tool: %s\n' "${required_tool}" >&2
        exit 1
    fi
done

"${script_dir}/bootstrap_sources.sh" --full-linux

actual_commit="$(git -C "${linux_dir}" rev-parse HEAD)"
if [[ "${actual_commit}" != "${expected_commit}" ]]; then
    printf 'Linux pin mismatch: %s\n' "${actual_commit}" >&2
    exit 1
fi

jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"

printf 'build_command: make -C %s O=%s ARCH=arm CROSS_COMPILE=%s drivers/remoteproc/stm32_rproc.o\n' \
    "${linux_dir}" "${output_dir}" "${cross_compile}"

make -C "${linux_dir}" O="${output_dir}" ARCH=arm \
    CROSS_COMPILE="${cross_compile}" multi_v7_defconfig
"${linux_dir}/scripts/config" --file "${output_dir}/.config" --enable STM32_RPROC
make -C "${linux_dir}" O="${output_dir}" ARCH=arm \
    CROSS_COMPILE="${cross_compile}" olddefconfig
make -C "${linux_dir}" O="${output_dir}" ARCH=arm \
    CROSS_COMPILE="${cross_compile}" -j"${jobs}" \
    drivers/remoteproc/stm32_rproc.o

object="${output_dir}/drivers/remoteproc/stm32_rproc.o"
compiler="$(${cross_compile}gcc --version | sed -n '1p')"
object_sha256="$(sha256sum "${object}" | awk '{print $1}')"

printf 'repo: %s\n' "${repo_dir}"
printf 'linux_commit: %s\n' "${actual_commit}"
printf 'compiler: %s\n' "${compiler}"
printf 'config: CONFIG_STM32_RPROC=y\n'
printf 'object: %s\n' "${object}"
printf 'object_sha256: %s\n' "${object_sha256}"
