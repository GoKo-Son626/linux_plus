#!/bin/sh

# Read-only inventory for STM32MP157 or SpacemiT K1 boards.
# Usage: sh collect_board_inventory.sh | tee board_inventory.txt

set -u

section()
{
	printf '\n## %s\n' "$1"
}

read_dt_string()
{
	file_name=$1
	if [ -r "$file_name" ]; then
		tr '\000' '\n' < "$file_name"
	else
		printf 'UNAVAILABLE: %s\n' "$file_name"
	fi
}

section "timestamp"
date -Iseconds 2>&1 || date 2>&1

section "kernel"
uname -a 2>&1
printf 'cmdline: '
cat /proc/cmdline 2>&1

section "device tree identity"
printf 'model:\n'
read_dt_string /proc/device-tree/model
printf 'compatible:\n'
read_dt_string /proc/device-tree/compatible

section "remoteproc classes"
if [ -d /sys/class/remoteproc ]; then
	for rproc_dir in /sys/class/remoteproc/remoteproc*; do
		[ -d "$rproc_dir" ] || continue
		printf '%s\n' "$rproc_dir"
		for attr_name in name state firmware recovery coredump; do
			if [ -r "$rproc_dir/$attr_name" ]; then
				printf '  %s: ' "$attr_name"
				cat "$rproc_dir/$attr_name" 2>&1
			fi
		done
	done
else
	printf 'UNAVAILABLE: /sys/class/remoteproc\n'
fi

section "rpmsg and virtio devices"
for class_dir in /sys/bus/rpmsg/devices /sys/bus/virtio/devices; do
	printf '%s:\n' "$class_dir"
	if [ -d "$class_dir" ]; then
		find "$class_dir" -mindepth 1 -maxdepth 1 -printf '  %f -> %l\n' 2>&1
	else
		printf '  UNAVAILABLE\n'
	fi
done

section "loaded modules"
if [ -r /proc/modules ]; then
	awk '$1 ~ /(remoteproc|rproc|rpmsg|virtio|mailbox|stm32|spacemit)/ { print }' /proc/modules
else
	printf 'UNAVAILABLE: /proc/modules\n'
fi

section "firmware candidates"
if [ -d /lib/firmware ]; then
	find /lib/firmware -maxdepth 3 -type f \
		\( -iname '*rpmsg*' -o -iname '*rproc*' -o -iname '*cm4*' -o -iname '*m4*' -o -iname '*esos*' \) \
		-printf '%p\n' 2>&1
else
	printf 'UNAVAILABLE: /lib/firmware\n'
fi

section "kernel config hints"
if [ -r /proc/config.gz ]; then
	zcat /proc/config.gz 2>/dev/null | awk '/^CONFIG_(REMOTEPROC|RPMSG|VIRTIO|MAILBOX|STM32_RPROC|ARCH_SPACEMIT)/ { print }'
elif [ -r "/boot/config-$(uname -r)" ]; then
	awk '/^CONFIG_(REMOTEPROC|RPMSG|VIRTIO|MAILBOX|STM32_RPROC|ARCH_SPACEMIT)/ { print }' "/boot/config-$(uname -r)"
else
	printf 'UNAVAILABLE: kernel config\n'
fi

section "recent remoteproc/rpmsg messages"
dmesg 2>&1 | awk 'BEGIN { IGNORECASE=1 } /remoteproc|rproc|rpmsg|virtio|mailbox|stm32|spacemit/ { print }' | tail -n 300
