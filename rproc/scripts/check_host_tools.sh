#!/bin/sh

# Verify the host-side toolchain required by the rproc/RPMI learning plan.

set -eu

require_tool()
{
	tool_name=$1
	if ! command -v "$tool_name" >/dev/null 2>&1; then
		printf 'FAIL  missing tool: %s\n' "$tool_name" >&2
		exit 1
	fi
}

for required_tool in \
	arm-none-eabi-gcc \
	arm-none-linux-gnueabihf-gcc \
	arm-none-linux-gnueabihf-readelf \
	riscv64-linux-gnu-gcc \
	riscv64-linux-gnu-readelf \
	clang \
	ld.lld \
	dtc \
	dt-validate \
	dt-doc-validate
do
	require_tool "$required_tool"
done

arm_object=$(mktemp -p /tmp linux-plus-arm.XXXXXX.o)
riscv_object=$(mktemp -p /tmp linux-plus-riscv.XXXXXX.o)

cleanup()
{
	[ ! -e "$arm_object" ] || unlink "$arm_object"
	[ ! -e "$riscv_object" ] || unlink "$riscv_object"
}

trap cleanup EXIT HUP INT TERM

printf '%s\n' 'int probe(void) { return 42; }' \
	| arm-none-linux-gnueabihf-gcc -x c -c -o "$arm_object" -
printf '%s\n' 'int probe(void) { return 42; }' \
	| riscv64-linux-gnu-gcc -x c -c -o "$riscv_object" -

file "$arm_object" | grep -q 'ELF 32-bit.*ARM.*EABI5'
file "$riscv_object" | grep -q 'ELF 64-bit.*RISC-V.*double-float ABI'

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname -- "$(dirname -- "$script_dir")")
stm32_schema="$repo_root/rproc/sources/linux-v7.2/Documentation/devicetree/bindings/remoteproc/st,stm32-rproc.yaml"

if [ -f "$stm32_schema" ]; then
	dt-doc-validate "$stm32_schema"
	printf 'PASS  STM32 remoteproc binding validates\n'
else
	printf 'SKIP  source tree not bootstrapped; schema unavailable\n'
fi

printf 'PASS  ARM bare-metal: %s\n' "$(arm-none-eabi-gcc -dumpfullversion)"
printf 'PASS  ARM Linux GNU: %s (%s)\n' \
	"$(arm-none-linux-gnueabihf-gcc -dumpfullversion)" \
	"$(arm-none-linux-gnueabihf-gcc -dumpmachine)"
printf 'PASS  RISC-V Linux GNU: %s (%s)\n' \
	"$(riscv64-linux-gnu-gcc -dumpfullversion)" \
	"$(riscv64-linux-gnu-gcc -dumpmachine)"
printf 'PASS  Clang: %s\n' "$(clang --version | sed -n '1s/^clang version //p')"
printf 'PASS  LLD: %s\n' "$(ld.lld --version)"
printf 'PASS  DTC: %s\n' "$(dtc --version)"
printf 'PASS  dt-schema: %s\n' "$(dt-validate --version)"
