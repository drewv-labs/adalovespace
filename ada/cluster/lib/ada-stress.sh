#!/usr/bin/env bash
# Ada Lovespace — Full Load Stress Test Utility
# Runs sustained CPU stress for thermal management validation.
# Available as "ada-stress" after linking to /usr/local/bin.
#
# Usage:
#   ada-stress-test 30            # Run 30-minute stress test
#   ada-stress-test --help        # Show usage information
#   ada-stress-test --dry-run     # Print what would run without executing
#
# Dependency: stress-ng (installed by build/core/debian/base_installs.sh)

set -euo pipefail

# ==============================================================================
# Globals & Defaults
# ==============================================================================

STRESS_DURATION=0
STRESS_SECONDS=0
DRY_RUN=false
CPU_COUNT=0
NODE_NAME=""
PID_STRESS=""

RESOLVED_REPO_ROOT="${ADA_ROOT:-}"

_resolve_repo_root() {
    if [[ -n "${RESOLVED_REPO_ROOT}" ]]; then
        echo "${RESOLVED_REPO_ROOT}"
        return 0
    fi

    local _candidate="$(cd "$(dirname "$BASH_SOURCE[0]")" && pwd)"
    while [[ "${_candidate}" != "/" ]]; do
        if [[ -f "${_candidate}/cluster.env" ]]; then
            RESOLVED_REPO_ROOT="${_candidate}"
            echo "${_candidate}"
            return 0
        fi
        _candidate="$(dirname "${_candidate}")"
    done

    if [[ -f "/opt/adalovespace/cluster.env" ]]; then
        RESOLVED_REPO_ROOT="/opt/adalovespace"
        echo "/opt/adalovespace"
        return 0
    fi

    echo "FATAL: Could not resolve repo root." >&2
    exit 1
}

_ADA_ROOT="$(_resolve_repo_root)"

# Source logging (if available)
if [[ -f "${_ADA_ROOT}/cluster/lib/ada-log.sh" ]]; then
    source "${_ADA_ROOT}/cluster/lib/ada-log.sh" >/dev/null 2>&1 || true
fi

# ==============================================================================
# Helpers
# ==============================================================================

_usage() {
    cat <<EOF
Usage: ada-stress-test <minutes> [options]

Sustained full-CPU load stress test for thermal management validation.

Arguments:
  minutes                 Duration in minutes (required).

Options:
  --help                  Show this help message and exit.
  --dry-run               Print what would run without executing.
  --cpus N                Override CPU count (defaults to auto-detect).

Examples:
  ada-stress-test 30                    # Run 30-minute full-CPU stress test
  ada-stress-test 60 --dry-run          # Show plan without executing
  ada-stress-test 15 --cpus 4           # Stress only 4 CPUs for 15 min

Dependency: stress-ng (installed by core build).

EOF
}

_read_temps() {
    for zone in /sys/class/thermal/thermal_zone*/; do
        [[ -d "${zone}" ]] || continue
        local type="" temp=""
        [[ -f "${zone}type" ]] && type="$(cat "${zone}type" 2>/dev/null)"
        if [[ -f "${zone}temp" ]]; then
            temp="$(awk '{printf "%.1f", $1/1000}' "${zone}temp" 2>/dev/null)"
        fi
        [[ -n "${type}" && -n "${temp}" ]] && echo "${type}: ${temp}°C"
    done

    command -v sensors &>/dev/null && sensors 2>/dev/null | grep -i "°C" || true
}

_max_temp() {
    local max=0
    while IFS= read -r line; do
        local val
        val=$(echo "${line}" | grep -oE '[0-9]+\.[0-9]+|^[0-9]+' | head -1)
        if [[ -n "${val}" ]] && awk "BEGIN {exit !(${val} > ${max})}"; then
            max="${val}"
        fi
    done <<< "$(_read_temps)"
    echo "${max}"
}

_setup_log() {
    local logfile_dir="/var/log/ada"
    [[ ! -w "${logfile_dir}" ]] && logfile_dir="${ADA_LOCAL_LOGS:-/tmp/ada-stress-logs}"
    mkdir -p "${logfile_dir}" 2>/dev/null || true
    LOG_FILE="${logfile_dir}/stress-test-${NODE_NAME}-$(date +%Y%m%d-%H%M%S).log"
}

# ==============================================================================
# Temp monitor — runs in background during stress
# ==============================================================================

_monitor_loop() {
    local interval=10
    local elapsed=0
    local peak_temp="N/A"

    { echo ""; echo "=== Stress Test Started: $(date) ==="; \
      echo "Nodes stressed: ${CPU_COUNT} CPUs (${NODE_NAME})"; \
      echo "---"; } >> "${LOG_FILE}"

    local start_temps="$(_read_temps)"
    echo "[${elapsed}s] Temperature at start: ${start_temps}" >> "${LOG_FILE}"
    peak_temp="$(_max_temp)"
    echo "[${elapsed}s] Peak temp so far: ${peak_temp}°C" >> "${LOG_FILE}"

    while (( elapsed < STRESS_SECONDS )); do
        sleep "${interval}"
        elapsed=$((elapsed + interval))

        local temps cur_peak
        temps="$(_read_temps)"
        cur_peak="$(_max_temp)"
        awk "BEGIN {exit !(${cur_peak} > ${peak_temp})}" && peak_temp="${cur_peak}"

        printf "[%-5ds] Temps: %-80s Peak: %s°C\n" "${elapsed}" "${temps}" "${peak_temp}" >> "${LOG_FILE}"

        (( elapsed % 60 == 0 )) && \
            ada-log "t1" "[stress] Elapsed: ${elapsed}s / ${STRESS_SECONDS}s | Peak temp: ${peak_temp}°C"
    done

    { echo "---"; echo "=== Stress Test Ended: $(date) ==="; \
      echo "Peak temperature observed: ${peak_temp}°C"; echo ""; } >> "${LOG_FILE}"
}

# ==============================================================================
# Main dispatch
# ==============================================================================

main() {
    if [[ $# -eq 0 ]]; then
        _usage
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --help|-h)   _usage; exit 0 ;;
            --dry-run)   DRY_RUN=true; shift ;;
            --cpus)
                CPU_COUNT="${2:-}"
                if [[ -z "${CPU_COUNT}" ]] || ! [[ "${CPU_COUNT}" =~ ^[0-9]+$ ]]; then
                    echo "ERROR: --cpus requires a positive integer" >&2; exit 1
                fi
                shift 2 ;;
            -*)          echo "ERROR: Unknown option: ${1}" >&2; _usage; exit 1 ;;
            *)
                if ! [[ "${1}" =~ ^[0-9]+$ ]]; then
                    echo "ERROR: Duration must be a positive integer (minutes)" >&2; exit 1
                fi
                STRESS_DURATION="${1}"
                STRESS_SECONDS=$((STRESS_DURATION * 60))
                shift ;;
        esac
    done

    if [[ "${STRESS_SECONDS}" -eq 0 ]]; then
        echo "ERROR: Duration must be specified (e.g., ada-stress-test 30)" >&2
        exit 1
    fi

    NODE_NAME="$(hostname)"

    # Auto-detect CPU count
    [[ -z "${CPU_COUNT}" ]] && CPU_COUNT=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)

    # Dry-run: print plan, verify stress-ng is available, exit
    if [[ "${DRY_RUN}" == true ]]; then
        echo "============================================="
        echo " Ada Lovespace — Stress Test (dry-run)"
        echo "============================================="
        echo " Node:           ${NODE_NAME}"
        echo " Duration:       ${STRESS_DURATION} minutes (${STRESS_SECONDS} seconds)"
        echo " CPUs to stress: ${CPU_COUNT}"
        echo ""

        command -v stress-ng &>/dev/null || {
            echo "ERROR: stress-ng not found. Run core build first:"
            echo "  bash cluster/core/build.sh debian" >&2
            exit 1
        }

        echo "[dry-run] Would run:"
        echo "         stress-ng --cpu ${CPU_COUNT} --throttle 1 --timeout ${STRESS_SECONDS}s"
        echo ""
        echo "[dry-run] Would monitor temperatures every 10s."
        echo "Remove --dry-run to execute."
        exit 0
    fi

    # Setup logging
    _setup_log

    echo ""
    echo "============================================="
    echo " Ada Lovespace — Stress Test"
    echo "============================================="
    echo " Node:           ${NODE_NAME}"
    echo " Duration:       ${STRESS_DURATION} minutes (${STRESS_SECONDS} seconds)"
    echo " CPUs to stress: ${CPU_COUNT}"
    echo " Log file:       ${LOG_FILE}"
    echo ""

    # Trap for clean shutdown on Ctrl+C / SIGTERM
    trap '_cleanup_and_report' EXIT INT TERM

    _cleanup_and_report() {
        local rc=$?
        echo ""; ada-log "main" "[stress] Cleaning up..."
        kill "${PID_STRESS}" 2>/dev/null || true
        wait "${PID_STRESS}" 2>/dev/null || true
        kill $(jobs -p) 2>/dev/null || true
        ada-log "yay" "[stress] Stress test completed or interrupted (exit code: ${rc})"
        echo ""; echo "Results logged to: ${LOG_FILE}"; exit "${rc}"
    }

    # Start temp monitor in background, then stress-ng
    _monitor_loop &
    local PID_MONITOR=$!

    ada-log "main" "[stress] Starting ${CPU_COUNT} CPU worker(s) for ${STRESS_SECONDS}s..."
    stress-ng --cpu "${CPU_COUNT}" --throttle 1 --timeout "${STRESS_SECONDS}s" &
    PID_STRESS=$!

    wait "${PID_STRESS}" || true
    sleep 2
    kill "${PID_MONITOR}" 2>/dev/null || true
    wait "${PID_MONITOR}" 2>/dev/null || true

    echo ""; ada-log "yay" "[stress] Stress test finished after ${STRESS_DURATION} minutes"
    echo "Results logged to: ${LOG_FILE}"; echo ""
}

main "$@"
