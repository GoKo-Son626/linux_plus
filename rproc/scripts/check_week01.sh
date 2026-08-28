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
    04_rpmsg_bridge.md 05_stm32_driver_map.md 06_week_summary.md; do
    require_complete "${week_dir}/notes/${note}" "note ${note}"
done

require_complete "${week_dir}/tests/conceptual_answers.md" "conceptual answers"
require_nonempty "${week_dir}/tests/week01_score.yaml" "score record"
require_complete "${week_dir}/evidence/k1_gap_matrix.md" "K1 evidence matrix"

score_file="${week_dir}/tests/week01_score.yaml"
if [[ -s "${score_file}" ]]; then
    conceptual="$(sed -n 's/^conceptual:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "${score_file}" | head -n 1)"
    source_trace="$(sed -n 's/^source_trace:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "${score_file}" | head -n 1)"
    score="$(sed -n 's/^total:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "${score_file}" | head -n 1)"
    if [[ "${conceptual}" =~ ^[0-9]+$ ]] && (( conceptual >= 0 && conceptual <= 60 )) && \
       [[ "${source_trace}" =~ ^[0-9]+$ ]] && (( source_trace >= 0 && source_trace <= 40 )) && \
       [[ "${score}" =~ ^[0-9]+$ ]] && (( score == conceptual + source_trace )) && \
       (( score >= 80 && score <= 100 )); then
        pass "weighted total >= 80 and section sums are valid"
    else
        fail "score must satisfy conceptual 0..60 + source_trace 0..40 = total 80..100"
    fi

    if rg -q '^blocking_errors:[[:space:]]*\[\][[:space:]]*$' "${score_file}"; then
        pass "no blocking conceptual errors"
    else
        fail "blocking_errors must be an empty YAML list after correction and retest"
    fi

    if rg -q '^reviewed_by_codex:[[:space:]]*true[[:space:]]*$' "${score_file}"; then
        pass "score reviewed by Codex"
    else
        fail "reviewed_by_codex must be true"
    fi
fi

build_log="${week_dir}/evidence/build_stm32_rproc.log"
runtime_log="${week_dir}/evidence/remoteproc_sysfs.log"
last_build_result="$(sed -n 's/^result:[[:space:]]*//p' "${build_log}" 2>/dev/null | tail -n 1)"
last_build_exit="$(sed -n 's/^exit_code:[[:space:]]*//p' "${build_log}" 2>/dev/null | tail -n 1)"
if { [[ -s "${build_log}" ]] && \
     [[ "${last_build_result}" == "PASS" ]] && \
     [[ "${last_build_exit}" == "0" ]] && \
     rg -q '^linux_commit:[[:space:]]*[0-9a-f]{40}$' "${build_log}" && \
     rg -q '^compiler:[[:space:]].+' "${build_log}" && \
     rg -q '^config:[[:space:]]*CONFIG_STM32_RPROC=y$' "${build_log}" && \
     rg -q '^object_sha256:[[:space:]]*[0-9a-f]{64}$' "${build_log}"; } || \
   { [[ -s "${runtime_log}" ]] && \
     rg -q '^result:[[:space:]]*PASS$' "${runtime_log}" && \
     rg -q '^reviewed_by_codex:[[:space:]]*true$' "${runtime_log}" && \
     rg -q '^board_identity:[[:space:]].+' "${runtime_log}" && \
     rg -q '^firmware:[[:space:]].+' "${runtime_log}" && \
     rg -q '^before_state:[[:space:]].+' "${runtime_log}" && \
     rg -q '^after_start_state:[[:space:]].+' "${runtime_log}" && \
     rg -q '^after_stop_state:[[:space:]].+' "${runtime_log}"; }; then
    pass "structured build or runtime evidence"
else
    fail "need structured PASS evidence in build_stm32_rproc.log or reviewed PASS in remoteproc_sysfs.log"
fi

completion="${week_dir}/completion_report.md"
if [[ -s "${completion}" ]] && ! rg -q 'TODO' "${completion}"; then
    pass "completion report has no TODO"
else
    fail "completion report is incomplete"
fi

exit "${failed}"
