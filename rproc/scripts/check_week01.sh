#!/usr/bin/env bash
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
week_dir="$(cd "${script_dir}/../week01" && pwd)"
failed=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failed=1; }

require_nonempty() {
    local path="$1"
    local label="$2"
    if [[ -s "${path}" ]]; then pass "${label}"; else fail "${label}: ${path}"; fi
}

require_complete() {
    local path="$1"
    local label="$2"
    if [[ -s "${path}" ]] && ! rg -q 'TODO' "${path}"; then
        pass "${label}"
    else
        fail "${label} is missing or still contains TODO: ${path}"
    fi
}

for note in \
    01_overview.md 02_rproc_boot_trace.md 03_resource_table_addressing.md \
    04_rpmsg_bridge.md 05_stm32_driver_map.md; do
    require_complete "${week_dir}/notes/${note}" "note ${note}"
done

require_complete "${week_dir}/tests/conceptual_answers.md" "conceptual answers"
require_nonempty "${week_dir}/tests/week01_score.yaml" "score record"
require_complete "${week_dir}/evidence/k1_gap_matrix.md" "K1 evidence matrix"

score_file="${week_dir}/tests/week01_score.yaml"
if [[ -s "${score_file}" ]]; then
    score="$(sed -n 's/^total:[[:space:]]*//p' "${score_file}" | head -n 1)"
    if [[ "${score}" =~ ^[0-9]+$ ]] && (( score >= 80 && score <= 100 )); then
        pass "conceptual/source total >= 80"
    else
        fail "score must be an integer from 80 to 100"
    fi
fi

build_log="${week_dir}/evidence/build_stm32_rproc.log"
runtime_log="${week_dir}/evidence/remoteproc_sysfs.log"
if { [[ -s "${build_log}" ]] && rg -q '^result:[[:space:]]*PASS$' "${build_log}"; } || \
   { [[ -s "${runtime_log}" ]] && rg -q '^result:[[:space:]]*PASS$' "${runtime_log}"; }; then
    pass "build or runtime evidence"
else
    fail "need PASS evidence in build_stm32_rproc.log or remoteproc_sysfs.log"
fi

completion="${week_dir}/completion_report.md"
if [[ -s "${completion}" ]] && ! rg -q 'TODO' "${completion}"; then
    pass "completion report has no TODO"
else
    fail "completion report is incomplete"
fi

exit "${failed}"
