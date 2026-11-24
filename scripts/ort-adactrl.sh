#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaCtrl Day-0 Operational Readiness Test (ORT)
# Path: adalovespace/scripts/ort-adactrl.sh
#
# Description:
#   Fail-fast bare-metal Day-0 ORT & Quiescent Baseline Profiler for
#   `AdaCtrl-RPI5` (`arm64` BCM2712 + RP1) and `AdaCtrl-RV2` (`riscv64` Ky X1):
#     1. `/sys/fs/cgroup/cgroup.controllers` exposes `cpuset` and `memory`
#        (and verifies zero `isolcpus=` / `CPUAffinity=` anti-patterns)
#     2. Active thread pinning via `ps -eLo pid,tid,psr,ni,cls,comm`:
#        - `phd2`/`phd2.bin` & `Xvfb` strictly on `SLICE_GUIDING_CPUS` (`CLS=TS`)
#        - `indiserver` & `indi_*` strictly on `SLICE_INDI_CPUS`
#        - `pigeoneer` strictly on `SLICE_OBSERVABILITY_CPUS`
#     3. `/proc/interrupts` confirms `xhci` and primary NIC (`eth0`/`end0`) IRQs
#        reside & increment on `CPU0` (`SLICE_SYSTEM_CPUS`) with zero bleed onto
#        `indi.slice` / `guiding.slice` cores
#     4. `ss -tlnp` confirms TCP listeners on `:7624`, `:8624`, and `:4400`
#     5. `lsusb -t` dual-xHCI root topology printout
#     6. Quiescent baseline snapshot (`vcgencmd get_throttled` == `0x0`,
#        thermal zones, and `cpufreq` current vs max) + JSON Provenance Manifest
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

# shellcheck source=../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ada_sanitize_locale
ada_resolve_caller
ada_detect_board

STAGE_TAG="day0-ort"
OUT_DIR="${ADA_SNAP_DIR:-${REAL_HOME}/.adalovespace/snapshots}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stage)   STAGE_TAG="${2:-day0-ort}"; shift 2 ;;
        --out-dir) OUT_DIR="${2:-$OUT_DIR}"; shift 2 ;;
        -h|--help)
            cat <<'EOF'
Usage:
  sudo ada ort [--stage <tag>] [--out-dir <dir>]
  sudo bash scripts/ort-adactrl.sh [--stage <tag>] [--out-dir <dir>]
EOF
            exit 0
            ;;
        *)
            log_fatal "Unknown option '$1' for ort-adactrl.sh"
            ;;
    esac
done

NODE_ENV="${ADA_NODE_ENV:-${REAL_HOME}/.adalovespace/node.env}"
if [[ -f "$NODE_ENV" ]]; then
    ada_kv_load "$NODE_ENV"
fi

BOARD_TAG="$(ada_normalize_board "${BOARD_TAG:-${ADA_DETECTED_BOARD:-rpi5}}")"
[[ -z "$BOARD_TAG" ]] && BOARD_TAG="rpi5"
if [[ -f "${ADA_ENGINE_ROOT}/boards/${BOARD_TAG}.env" ]]; then
    ada_kv_load "${ADA_ENGINE_ROOT}/boards/${BOARD_TAG}.env"
fi
if [[ -f "$NODE_ENV" ]]; then
    ada_kv_load "$NODE_ENV"
fi

SLICE_SYSTEM_CPUS="${SLICE_SYSTEM_CPUS:-0}"
SLICE_USER_CPUS="${SLICE_USER_CPUS:-0}"
SLICE_OBSERVABILITY_CPUS="${SLICE_OBSERVABILITY_CPUS:-0}"
SLICE_INDI_CPUS="${SLICE_INDI_CPUS:-1-2}"
SLICE_GUIDING_CPUS="${SLICE_GUIDING_CPUS:-3}"
INDI_PORT="${INDI_PORT:-7624}"
INDIWEB_PORT="${INDIWEB_PORT:-8624}"
PHD2_PORT="${PHD2_PORT:-4400}"
ENABLE_PIGEONEER="${ENABLE_PIGEONEER:-true}"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

ort_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "\033[1;32m[PASS]\033[0m %s\n" "$1"
}

ort_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf "\033[1;31m[FAIL]\033[0m %s\n" "$1"
}

ort_warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    printf "\033[1;33m[WARN]\033[0m %s\n" "$1"
}

# Expand CPU range syntax (e.g. "1-2" -> "1,2", "0,2-4" -> "0,2,3,4")
expand_cpuset() {
    local spec="$1"
    local out=()
    local token start end i
    IFS=',' read -ra tokens <<< "$spec"
    for token in "${tokens[@]}"; do
        token="${token//[[:space:]]/}"
        [[ -z "$token" ]] && continue
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start="${BASH_REMATCH[1]}"
            end="${BASH_REMATCH[2]}"
            for ((i = start; i <= end; i++)); do
                out+=("$i")
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            out+=("$token")
        fi
    done
    local IFS=','
    printf '%s\n' "${out[*]}"
}

psr_in_set() {
    local psr="$1"
    local csv_set=",$2,"
    [[ "$csv_set" == *",${psr},"* ]]
}

SYSTEM_PSR_CSV="$(expand_cpuset "$SLICE_SYSTEM_CPUS")"
OBS_PSR_CSV="$(expand_cpuset "$SLICE_OBSERVABILITY_CPUS")"
INDI_PSR_CSV="$(expand_cpuset "$SLICE_INDI_CPUS")"
GUIDING_PSR_CSV="$(expand_cpuset "$SLICE_GUIDING_CPUS")"

HOST_NOW="$(hostname 2>/dev/null || echo "adactrl")"
PRIMARY_NIC="$(ada_detect_primary_nic)"
TS_UTC="$(date -u '+%Y%m%dT%H%M%SZ')"
ISO_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

printf "\n======================================================================\n"
printf " DREW-V Labs // AdaCtrl Day-0 Operational Readiness Test (ORT)\n"
printf "   Host / Board : %s (%s / %s)\n" "$HOST_NOW" "$BOARD_TAG" "${ADA_DT_MODEL}"
printf "   Kernel       : %s\n" "$(uname -r)"
printf "   Timestamp    : %s\n" "$ISO_UTC"
printf "======================================================================\n"

# ------------------------------------------------------------------------------
# Check 1: Cgroup v2 Controllers (`cpuset` + `memory`) & Boot Hygiene
# ------------------------------------------------------------------------------
log_step "1/6. Cgroup v2 Controllers & Slice Topology"

CGROUP_CONTROLLERS=""
if [[ -r /sys/fs/cgroup/cgroup.controllers ]]; then
    CGROUP_CONTROLLERS="$(cat /sys/fs/cgroup/cgroup.controllers)"
fi
printf "  /sys/fs/cgroup/cgroup.controllers: %s\n" "${CGROUP_CONTROLLERS:-<unreadable>}"

for ctrl in cpuset memory; do
    if [[ " ${CGROUP_CONTROLLERS} " == *" ${ctrl} "* ]]; then
        ort_pass "cgroup v2 controller '${ctrl}' active in /sys/fs/cgroup/cgroup.controllers"
    else
        ort_fail "cgroup v2 controller '${ctrl}' MISSING in /sys/fs/cgroup/cgroup.controllers (reboot required if cmdline was just updated)"
    fi
done

PROC_CMDLINE="$(cat /proc/cmdline 2>/dev/null || true)"
if grep -Eq '(^|[[:space:]])isolcpus=' <<< "$PROC_CMDLINE"; then
    ort_fail "Legacy 'isolcpus=' detected in /proc/cmdline (forbidden)"
else
    ort_pass "No legacy 'isolcpus=' present in /proc/cmdline"
fi

if [[ -f /etc/systemd/system.conf ]] && grep -Eq '^[[:space:]]*CPUAffinity[[:space:]]*=' /etc/systemd/system.conf; then
    ort_fail "Global 'CPUAffinity=' detected in /etc/systemd/system.conf (overrides child slices)"
else
    ort_pass "No global 'CPUAffinity=' override in /etc/systemd/system.conf"
fi

if ip link show usb0 >/dev/null 2>&1; then
    ort_fail "Legacy MaryGuider usb0 interface still present"
else
    ort_pass "MaryGuider usb0 gadget tether absent"
fi

# ------------------------------------------------------------------------------
# Check 2: Active Thread Pinning & Scheduler Class (`ps -eLo pid,tid,psr,ni,cls,comm`)
# ------------------------------------------------------------------------------
log_step "2/6. Active Thread Pinning & Scheduler Verification (ps -eLo)"

PS_DUMP="$(ps -eLo pid=,tid=,psr=,ni=,cls=,comm=)"

verify_threads() {
    local label="$1"
    local comm_regex="$2"
    local allowed_csv="$3"
    local require_running="$4"
    local expected_ni="${5:-}"

    local matched_lines count=0 bad_psr=0 bad_cls=0 bad_ni=0
    matched_lines="$(awk -v re="$comm_regex" '$6 ~ re {print $0}' <<< "$PS_DUMP")"

    if [[ -z "$matched_lines" ]]; then
        if [[ "$require_running" == "true" ]]; then
            ort_fail "${label}: no active threads matching '${comm_regex}'"
        else
            ort_warn "${label}: no active threads matching '${comm_regex}' right now"
        fi
        return 0
    fi

    local pid tid psr ni cls comm
    while read -r pid tid psr ni cls comm; do
        [[ -z "${pid:-}" ]] && continue
        count=$((count + 1))
        printf "    PID=%-7s TID=%-7s PSR=%-2s NI=%-4s CLS=%-4s COMM=%s\n" "$pid" "$tid" "$psr" "$ni" "$cls" "$comm"
        if ! psr_in_set "$psr" "$allowed_csv"; then
            bad_psr=$((bad_psr + 1))
        fi
        if [[ "$cls" == "FF" || "$cls" == "RR" ]]; then
            bad_cls=$((bad_cls + 1))
        fi
        if [[ -n "$expected_ni" && "$ni" != "$expected_ni" ]]; then
            bad_ni=$((bad_ni + 1))
        fi
    done <<< "$matched_lines"

    if [[ "$bad_psr" -eq 0 ]]; then
        ort_pass "${label}: all ${count} thread(s) strictly pinned to PSR in {${allowed_csv}}"
    else
        ort_fail "${label}: ${bad_psr}/${count} thread(s) outside allowed PSR set {${allowed_csv}}"
    fi

    if [[ "$bad_cls" -gt 0 ]]; then
        ort_fail "${label}: ${bad_cls} thread(s) running SCHED_FIFO/SCHED_RR (USB spin-lock hazard)"
    fi

    if [[ -n "$expected_ni" ]]; then
        if [[ "$bad_ni" -eq 0 ]]; then
            ort_pass "${label}: Nice=${expected_ni} & CLS=TS verified across ${count} thread(s)"
        else
            ort_fail "${label}: ${bad_ni}/${count} thread(s) did not match Nice=${expected_ni}"
        fi
    fi
}

verify_threads "Xvfb (guiding.slice)" '^Xvfb$' "$GUIDING_PSR_CSV" "true" ""
verify_threads "PHD2 (guiding.slice)" '^phd2(\.bin)?$' "$GUIDING_PSR_CSV" "true" "-10"
verify_threads "INDI (indi.slice)" '^(indiserver|indi-web|indi_.*)$' "$INDI_PSR_CSV" "true" ""
if [[ "$ENABLE_PIGEONEER" == "true" ]]; then
    verify_threads "Pigeoneer (observability.slice)" '^pigeoneer$' "$OBS_PSR_CSV" "true" ""
fi

# ------------------------------------------------------------------------------
# Check 3: `/proc/interrupts` RP1 / SoC IRQ Residency & Increment on `CPU0`
# ------------------------------------------------------------------------------
log_step "3/6. /proc/interrupts IRQ Affinity (xhci & ${PRIMARY_NIC} -> CPU0)"

IRQ_T0="$(cat /proc/interrupts)"
sleep 0.30
IRQ_T1="$(cat /proc/interrupts)"

check_irq_family() {
    local label="$1"
    local pattern="$2"
    local result

    result="$(python3 - "$pattern" "$SYSTEM_PSR_CSV" "$INDI_PSR_CSV" "$GUIDING_PSR_CSV" "$IRQ_T0" "$IRQ_T1" <<'PY'
import re
import sys

pat = re.compile(sys.argv[1], re.IGNORECASE)
sys_cpus = {int(x) for x in sys.argv[2].split(",") if x}
iso_cpus = {int(x) for x in (sys.argv[3] + "," + sys.argv[4]).split(",") if x}
iso_cpus -= sys_cpus

def parse(blob: str) -> dict[str, list[int]]:
    lines = blob.splitlines()
    if not lines:
        return {}
    ncpus = len(lines[0].split())
    rows: dict[str, list[int]] = {}
    for line in lines[1:]:
        if not pat.search(line):
            continue
        parts = line.split()
        if len(parts) < ncpus + 1:
            continue
        irq_id = parts[0].rstrip(":")
        try:
            counts = [int(parts[i + 1]) for i in range(ncpus)]
        except ValueError:
            continue
        desc = " ".join(parts[1 + ncpus:])
        rows[f"{irq_id} ({desc})"] = counts
    return rows

r0 = parse(sys.argv[5])
r1 = parse(sys.argv[6])

if not r1:
    print("MISSING|0|0|0|none")
    sys.exit(0)

sys_total = 0
sys_delta = 0
iso_delta = 0
details = []
for key, c1 in r1.items():
    c0 = r0.get(key, c1)
    st = sum(c1[c] for c in sys_cpus if c < len(c1))
    sd = sum((c1[c] - c0[c]) for c in sys_cpus if c < len(c1))
    idlt = sum((c1[c] - c0[c]) for c in iso_cpus if c < len(c1))
    sys_total += st
    sys_delta += sd
    iso_delta += idlt
    details.append(f"{key}: cpu0_total={st} delta_sys=+{sd} delta_iso=+{idlt}")

status = "PASS" if (sys_total > 0 and iso_delta == 0) else "FAIL"
print(f"{status}|{sys_total}|{sys_delta}|{iso_delta}|" + "; ".join(details))
PY
)"

    local st sys_tot sys_dlt iso_dlt info
    IFS='|' read -r st sys_tot sys_dlt iso_dlt info <<< "$result"
    printf "    %s\n" "$info"
    if [[ "$st" == "MISSING" ]]; then
        ort_warn "${label}: no matching IRQ line for '${pattern}' in /proc/interrupts"
    elif [[ "$st" == "PASS" ]]; then
        ort_pass "${label}: IRQs servicing on CPU{${SYSTEM_PSR_CSV}} (total=${sys_tot}, 300ms_delta=+${sys_dlt}, isolated_delta=${iso_dlt})"
    else
        ort_fail "${label}: IRQ bleed or zero CPU{${SYSTEM_PSR_CSV}} count (sys_total=${sys_tot}, isolated_delta=+${iso_dlt})"
    fi
}

check_irq_family "xHCI Host Controllers" 'xhci'
check_irq_family "Primary NIC (${PRIMARY_NIC})" "\\b${PRIMARY_NIC}\\b"

# ------------------------------------------------------------------------------
# Check 4: Active TCP Listeners (`7624` indiserver, `8624` indiweb, `4400` phd2)
# ------------------------------------------------------------------------------
log_step "4/6. TCP Socket Listeners (ss -tlnp)"

SS_OUT="$(ss -tlnp 2>/dev/null || true)"
grep -E ":(${INDI_PORT}|${INDIWEB_PORT}|${PHD2_PORT})\\b" <<< "$SS_OUT" | sed 's/^/    /' || true

check_port() {
    local port="$1"
    local svc_desc="$2"
    if grep -Eq ":${port}\\b" <<< "$SS_OUT"; then
        ort_pass "TCP :${port} (${svc_desc}) listening"
    else
        ort_fail "TCP :${port} (${svc_desc}) NOT listening"
    fi
}

check_port "$INDI_PORT" "indiserver"
check_port "$INDIWEB_PORT" "indiwebmanager"
check_port "$PHD2_PORT" "phd2 server"

# ------------------------------------------------------------------------------
# Check 5: Dual-xHCI USB Topology Printout (`lsusb -t`)
# ------------------------------------------------------------------------------
log_step "5/6. Dual-xHCI Root USB Topology (lsusb -t)"

LSUSB_TREE=""
if command -v lsusb >/dev/null 2>&1; then
    LSUSB_TREE="$(lsusb -t 2>&1 || true)"
    sed 's/^/    /' <<< "$LSUSB_TREE"
    printf "\n  Enumerated USB Devices (lsusb):\n"
    lsusb 2>&1 | sed 's/^/    /' || true
    ort_pass "Captured lsusb -t topology for visual dual-xHCI root verification"
else
    ort_fail "lsusb utility missing (install usbutils)"
fi

# ------------------------------------------------------------------------------
# Check 6: Quiescent Baseline Snapshot (Throttling, Thermal Zones, cpufreq)
# ------------------------------------------------------------------------------
log_step "6/6. Quiescent Baseline Profiling (Power, Thermal & CPU Frequency)"

THROTTLED_HEX="n/a"
if command -v vcgencmd >/dev/null 2>&1; then
    THROTTLED_RAW="$(vcgencmd get_throttled 2>/dev/null || echo "throttled=unknown")"
    THROTTLED_HEX="${THROTTLED_RAW#*=}"
    THROTTLED_HEX="${THROTTLED_HEX//[[:space:]]/}"
    printf "    vcgencmd get_throttled : %s\n" "$THROTTLED_RAW"
    if [[ "$THROTTLED_HEX" == "0x0" ]]; then
        ort_pass "PMIC / PoE 5V rail clean (vcgencmd get_throttled == 0x0)"
    else
        ort_fail "Undervoltage or thermal throttling detected (vcgencmd get_throttled == ${THROTTLED_HEX}, expected 0x0)"
    fi
else
    printf "    vcgencmd               : not applicable (%s)\n" "$BOARD_TAG"
fi

THERMAL_SUMMARY=()
for tz in /sys/class/thermal/thermal_zone*; do
    [[ -r "${tz}/temp" ]] || continue
    tz_name="$(basename "$tz")"
    tz_type="$(cat "${tz}/type" 2>/dev/null || echo "unknown")"
    tz_raw="$(cat "${tz}/temp" 2>/dev/null || echo "0")"
    tz_c="$(awk -v v="$tz_raw" 'BEGIN { printf "%.2f", v / 1000.0 }')"
    printf "    %-15s (%-14s): %s C\n" "$tz_name" "$tz_type" "$tz_c"
    THERMAL_SUMMARY+=("${tz_name}:${tz_type}:${tz_c}")
done
if [[ "${#THERMAL_SUMMARY[@]}" -gt 0 ]]; then
    ort_pass "Read ${#THERMAL_SUMMARY[@]} SoC thermal sensor zone(s)"
else
    ort_warn "No /sys/class/thermal/thermal_zone*/temp sensors exposed"
fi

CPUFREQ_SUMMARY=()
for cpudir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
    [[ -d "$cpudir" ]] || continue
    cpu_id="$(basename "$(dirname "$cpudir")")"
    cur_khz="$(cat "${cpudir}/scaling_cur_freq" 2>/dev/null || cat "${cpudir}/cpuinfo_cur_freq" 2>/dev/null || echo "0")"
    max_khz="$(cat "${cpudir}/scaling_max_freq" 2>/dev/null || cat "${cpudir}/cpuinfo_max_freq" 2>/dev/null || echo "0")"
    gov="$(cat "${cpudir}/scaling_governor" 2>/dev/null || echo "unknown")"
    cur_mhz="$((cur_khz / 1000))"
    max_mhz="$((max_khz / 1000))"
    printf "    %-6s governor=%-12s cur=%4d MHz / max=%4d MHz\n" "$cpu_id" "$gov" "$cur_mhz" "$max_mhz"
    CPUFREQ_SUMMARY+=("${cpu_id}:${gov}:${cur_khz}:${max_khz}")
done
if [[ "${#CPUFREQ_SUMMARY[@]}" -gt 0 ]]; then
    ort_pass "Captured cpufreq scaling profile across ${#CPUFREQ_SUMMARY[@]} core(s)"
else
    ort_warn "cpufreq sysfs nodes not exposed by active kernel"
fi

# ------------------------------------------------------------------------------
# Emit Baseline Provenance Manifest JSON + SHA-256 Digest
# ------------------------------------------------------------------------------
install -d -m 0750 -o "$REAL_USER" -g "$REAL_GRP" "$OUT_DIR"
MANIFEST_PATH="${OUT_DIR}/ort-${STAGE_TAG}-${HOST_NOW}-${TS_UTC}.json"

python3 - "$MANIFEST_PATH" "$ISO_UTC" "$STAGE_TAG" "$HOST_NOW" "$BOARD_TAG" "${ADA_DT_MODEL}" \
    "$CGROUP_CONTROLLERS" "$THROTTLED_HEX" "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT" \
    "$LSUSB_TREE" "${THERMAL_SUMMARY[*]:-}" "${CPUFREQ_SUMMARY[*]:-}" <<'PY'
import json
import os
import platform
import sys

(
    out_path,
    iso_utc,
    stage,
    host,
    board,
    dt_model,
    controllers,
    throttled,
    passed,
    failed,
    warned,
    lsusb_tree,
    thermals_raw,
    cpufreq_raw,
) = sys.argv[1:15]

thermals = []
for item in thermals_raw.split():
    parts = item.split(":")
    if len(parts) == 3:
        thermals.append({"zone": parts[0], "type": parts[1], "temp_c": float(parts[2])})

cpufreq = []
for item in cpufreq_raw.split():
    parts = item.split(":")
    if len(parts) == 4:
        cpufreq.append({
            "cpu": parts[0],
            "governor": parts[1],
            "scaling_cur_khz": int(parts[2]),
            "scaling_max_khz": int(parts[3]),
        })

doc = {
    "schema": "adalovespace.ort.v1",
    "timestamp_utc": iso_utc,
    "stage": stage,
    "hostname": host,
    "board_tag": board,
    "device_tree_model": dt_model,
    "arch": platform.machine(),
    "kernel": platform.release(),
    "cgroup_controllers": controllers.split(),
    "vcgencmd_throttled": throttled,
    "thermal_zones": thermals,
    "cpufreq": cpufreq,
    "lsusb_tree": lsusb_tree,
    "summary": {
        "status": "PASS" if int(failed) == 0 else "FAIL",
        "pass_count": int(passed),
        "fail_count": int(failed),
        "warn_count": int(warned),
    },
}

tmp_path = f"{out_path}.tmp.{os.getpid()}"
with open(tmp_path, "w", encoding="utf-8") as fh:
    json.dump(doc, fh, indent=2)
    fh.write("\n")
os.replace(tmp_path, out_path)
PY

chown "${REAL_USER}:${REAL_GRP}" "$MANIFEST_PATH" 2>/dev/null || true
chmod 0640 "$MANIFEST_PATH"

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$MANIFEST_PATH" > "${MANIFEST_PATH}.sha256"
    chown "${REAL_USER}:${REAL_GRP}" "${MANIFEST_PATH}.sha256" 2>/dev/null || true
fi

printf "\n======================================================================\n"
printf " ORT Summary: PASS=%d | FAIL=%d | WARN=%d\n" "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT"
printf " Provenance : %s\n" "$MANIFEST_PATH"
printf "======================================================================\n"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi
exit 0
