#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaCtrl On-Scope Node Convergence Orchestrator
# Path: adalovespace/src/adastak/adascope/nodes/adactrl/build.sh
#
# Description:
#   Converges `AdaCtrl-RPI5` (`arm64` BCM2712 + RP1) and `AdaCtrl-RV2` (`riscv64`
#   SpacemiT Ky X1) declaratively from `~/.adalovespace/node.env`:
#     1. OS & Hardware Normalization (`rvdk` on `riscv64`; native RPi5 tuner on `arm64`)
#     2. `MaryGuider-RPZ2` (`usb0`) Decommissioning & Cutover Hygiene
#     3. Declarative `systemd` Cgroup v2 Core Partitioning (No `isolcpus=`)
#     4. `CarrierPigeons` (`pigeoneer.service`) Telemetry in `observability.slice`
#     5. `INDI` (`indiwebmanager.service` + `indiserver` + rig XMLs) in `indi.slice`
#     6. Decoupled Headless `Xvfb` + `PHD2` (`xvfb-guiding` + `phd2`) in `guiding.slice`
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/../../../../.." && pwd)}"

# shellcheck source=../../../../../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"
# shellcheck source=../../../../../lib/cgroups.sh
source "${ADA_ENGINE_ROOT}/lib/cgroups.sh"

ADMIN_USER="${ADMIN_USER:?ADMIN_USER required}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:-adactrl-${BOARD_TAG:-rpi5}}"
BOARD_TAG="${BOARD_TAG:-rpi5}"
BOARD_ARCH="${BOARD_ARCH:-$(uname -m)}"
RVDK_TUNE_PROFILE="${RVDK_TUNE_PROFILE:-ai}"

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# Stage 1: OS & Board Baseline Normalization
# ------------------------------------------------------------------------------
log_step "1/6. OS & Board Normalization (${TARGET_HOSTNAME} | ${BOARD_TAG})"

if [[ "${BOARD_RVDK_NATIVE:-false}" == "true" && "$(uname -m)" == "riscv64" ]]; then
    RVDK_BIN="${RVDK_BIN:-/usr/local/bin/rvdk}"
    [[ ! -x "$RVDK_BIN" && -x /usr/bin/rvdk ]] && RVDK_BIN="/usr/bin/rvdk"
    [[ -x "$RVDK_BIN" ]] || log_fatal "RVDK CLI not found at ${RVDK_BIN}"

    RVDK_EXTRA=()
    [[ "${ADA_NO_APT_UPDATE:-false}" == "true" ]] && RVDK_EXTRA+=(--no-apt-update)
    "$RVDK_BIN" day0 --user "$ADMIN_USER" --hostname "$TARGET_HOSTNAME" --nopasswd ${RVDK_EXTRA[@]+"${RVDK_EXTRA[@]}"}
    "$RVDK_BIN" deeptune --tune "$RVDK_TUNE_PROFILE" --no-apt-update
else
    # Transitional arm64 / amd64 headless normalization (e.g. AdaCtrl-RPI5 Debian 13)
    if ! id -u "$ADMIN_USER" >/dev/null 2>&1; then
        log_fatal "Admin/runtime user '${ADMIN_USER}' does not exist on this system."
    fi

    # 1a. Passwordless sudoers drop-in
    SUDOERS_FILE="/etc/sudoers.d/010_${ADMIN_USER}_nopasswd"
    if ada_write_if_changed "$SUDOERS_FILE" 0440 <<EOF
${ADMIN_USER} ALL=(ALL) NOPASSWD: ALL
EOF
    then
        if ! visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
            rm -f "$SUDOERS_FILE"
            log_fatal "visudo validation failed on ${SUDOERS_FILE}"
        fi
        log_ok "Converged passwordless sudoers drop-in (${SUDOERS_FILE})"
    else
        log_skip "Sudoers drop-in already converged (${SUDOERS_FILE})"
    fi

    # 1b. Hardware device groups for USB cameras, serial mounts, and GPIO
    WANT_GROUPS=()
    for grp in dialout video plugdev input render gpio i2c spi tty; do
        if getent group "$grp" >/dev/null 2>&1 && ! id -nG "$ADMIN_USER" | tr ' ' '\n' | grep -qx "$grp"; then
            WANT_GROUPS+=("$grp")
        fi
    done
    if [[ "${#WANT_GROUPS[@]}" -gt 0 ]]; then
        IFS=,
        usermod -aG "${WANT_GROUPS[*]}" "$ADMIN_USER"
        unset IFS
        log_ok "Added ${ADMIN_USER} to hardware groups: ${WANT_GROUPS[*]}"
    else
        log_skip "User ${ADMIN_USER} already holds required hardware groups"
    fi

    # 1c. Mask sleep/hibernate targets & silence background jitter timers/daemons
    SLEEP_MASKED="true"
    for tgt in sleep.target suspend.target hibernate.target hybrid-sleep.target; do
        if [[ "$(systemctl is-enabled "$tgt" 2>/dev/null || true)" != "masked" ]]; then
            SLEEP_MASKED="false"
        fi
    done
    if [[ "$SLEEP_MASKED" == "false" ]]; then
        systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true
        log_ok "Masked sleep/suspend/hibernate targets"
    else
        log_skip "Sleep/suspend/hibernate targets already masked"
    fi

    PRIMARY_NIC="$(ada_detect_primary_nic)"
    IS_WIFI="false"
    [[ "$PRIMARY_NIC" == wl* || -d "/sys/class/net/${PRIMARY_NIC}/wireless" ]] && IS_WIFI="true"

    NOISE_UNITS=(apt-daily.timer apt-daily-upgrade.timer unattended-upgrades.service bluetooth.service ModemManager.service multipathd.service multipathd.socket)
    [[ "$IS_WIFI" == "false" ]] && NOISE_UNITS+=(wpa_supplicant.service)

    STOPPED_UNITS=()
    for u in "${NOISE_UNITS[@]}"; do
        if systemctl is-active --quiet "$u" 2>/dev/null || systemctl is-enabled --quiet "$u" 2>/dev/null; then
            systemctl disable --now "$u" >/dev/null 2>&1 || true
            STOPPED_UNITS+=("$u")
        fi
    done
    if [[ "${#STOPPED_UNITS[@]}" -gt 0 ]]; then
        log_ok "Disabled background jitter units: ${STOPPED_UNITS[*]}"
    else
        log_skip "Background jitter timers & unused radio units already disabled"
    fi

    # 1d. Verify Raspberry Pi 5 USB max current unlock (`usb_max_current_enable=1`)
    if [[ "$BOARD_TAG" == "rpi5" && -f /boot/firmware/config.txt ]]; then
        if grep -Eq '^[[:space:]]*usb_max_current_enable=1([[:space:]#]|$)' /boot/firmware/config.txt; then
            log_skip "RPi5 USB high-current mode (usb_max_current_enable=1) already active"
        else
            {
                cat /boot/firmware/config.txt
                printf '\n# Managed by AdaLovespace — Unlock 1.6A USB rail for ZWO cameras/EFW\nusb_max_current_enable=1\n'
            } | ada_atomic_write /boot/firmware/config.txt 0644
            export ADA_REBOOT_REQUIRED="true"
            log_ok "Enabled usb_max_current_enable=1 in /boot/firmware/config.txt"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# Stage 2: MaryGuider-RPZ2 Decommissioning & Cutover Hygiene
# ------------------------------------------------------------------------------
log_step "2/6. MaryGuider-RPZ2 Decommissioning & usb0 Cutover Hygiene"
if [[ "${DECOMMISSION_MARYGUIDER:-true}" == "true" ]]; then
    bash "${SCRIPT_DIR}/decommission-maryguider.sh"
else
    log_skip "MaryGuider decommissioning skipped (DECOMMISSION_MARYGUIDER=false)"
fi

# ------------------------------------------------------------------------------
# Stage 3: Declarative `systemd` Cgroup v2 Core Partitioning
# ------------------------------------------------------------------------------
log_step "3/6. Declarative systemd Cgroup v2 Core Partitioning (${BOARD_TAG})"
if [[ "${ENABLE_CGROUP_PARTITIONING:-true}" == "true" ]]; then
    ada_converge_cgroup_boot_cmdline
    ada_converge_cgroup_slices
else
    log_skip "Cgroup v2 partitioning skipped (ENABLE_CGROUP_PARTITIONING=false)"
fi

# ------------------------------------------------------------------------------
# Stage 4: CarrierPigeons Edge Telemetry (`pigeoneer.service` -> `observability.slice`)
# ------------------------------------------------------------------------------
log_step "4/6. CarrierPigeons Edge Telemetry (pigeoneer.service)"
if [[ "${ENABLE_PIGEONEER:-true}" == "true" ]]; then
    if [[ -x /usr/local/bin/pigeoneer && -f /etc/systemd/system/pigeoneer.service ]]; then
        if ! systemctl is-active --quiet pigeoneer.service 2>/dev/null; then
            systemctl daemon-reload
            systemctl enable --now pigeoneer.service
            log_ok "Started existing pigeoneer.service in observability.slice"
        else
            log_skip "pigeoneer.service already installed and active in $(systemctl show -p Slice --value pigeoneer.service 2>/dev/null || echo observability.slice)"
        fi
    else
        log_info "Installing CarrierPigeons pigeoneer daemon..."
        PIG_INSTALL_URL="${PIGEONEER_INSTALL_URL:-https://raw.githubusercontent.com/drewv-labs/carrierpigeons/main/deployments/install-pigeoneer.sh}"
        PIGEONEER_NODE_ID="${PIGEONEER_NODE_ID:-$TARGET_HOSTNAME}" \
        PIGEONEER_BROKER_URL="${PIGEONEER_BROKER_URL:-tcp://jakebase:1883}" \
        PIGEONEER_TAGS="${PIGEONEER_TAGS:-${BOARD_ARCH},${BOARD_TAG},adascope,adactrl}" \
        PIGEONEER_MQTT_USERNAME="${PIGEONEER_MQTT_USERNAME:-}" \
        PIGEONEER_MQTT_PASSWORD="${PIGEONEER_MQTT_PASSWORD:-}" \
        PIGEONEER_ENABLE_GPU_GROUPS="true" \
            bash -c "curl -fsSL '${PIG_INSTALL_URL}' | bash"
        systemctl daemon-reload
        systemctl restart pigeoneer.service
        log_ok "Installed & bound pigeoneer.service into observability.slice"
    fi
else
    log_skip "CarrierPigeons pigeoneer skipped (ENABLE_PIGEONEER=false)"
fi

# ------------------------------------------------------------------------------
# Stage 5: INDI Server + ZWO ASI + `indiwebmanager.service` (`indi.slice`)
# ------------------------------------------------------------------------------
log_step "5/6. INDI Server & Web Manager (indi.slice -> :${INDI_PORT:-7624} / :${INDIWEB_PORT:-8624})"
if [[ "${ENABLE_INDI:-true}" == "true" ]]; then
    bash "${SCRIPT_DIR}/indi/build.sh"
else
    log_skip "INDI stack skipped (ENABLE_INDI=false)"
fi

# ------------------------------------------------------------------------------
# Stage 6: Decoupled Headless `Xvfb` + `PHD2` (`guiding.slice`)
# ------------------------------------------------------------------------------
log_step "6/6. Decoupled Headless Xvfb + PHD2 (guiding.slice -> :${PHD2_PORT:-4400})"
if [[ "${ENABLE_PHD2:-true}" == "true" ]]; then
    bash "${SCRIPT_DIR}/phd2/build.sh"
else
    log_skip "Headless PHD2 skipped (ENABLE_PHD2=false)"
fi

# ------------------------------------------------------------------------------
# Post-Forge Summary & Reboot Readiness Notice
# ------------------------------------------------------------------------------
PRIMARY_NIC="$(ada_detect_primary_nic)"
LAN_IP="$(ip -o -4 addr show dev "$PRIMARY_NIC" scope global 2>/dev/null | awk '{split($4,a,"/"); print a[1]; exit}' || echo "<node-ip>")"

cat <<EOF

======================================================================
 DREW-V Labs // AdaCtrl Convergence Complete (${TARGET_HOSTNAME})
   Board / Arch       : ${BOARD_TAG} (${BOARD_ARCH})
   system/user.slice  : AllowedCPUs=${SLICE_SYSTEM_CPUS}
   observability.slice: AllowedCPUs=${SLICE_OBSERVABILITY_CPUS} (pigeoneer.service)
   indi.slice         : AllowedCPUs=${SLICE_INDI_CPUS} (indiwebmanager -> :${INDIWEB_PORT:-8624}, indiserver -> :${INDI_PORT:-7624})
   guiding.slice      : AllowedCPUs=${SLICE_GUIDING_CPUS} (xvfb-guiding ${PHD2_DISPLAY:-:99} + phd2 -> :${PHD2_PORT:-4400})
   inference.slice    : AllowedCPUs=${SLICE_INFERENCE_CPUS:-<stub>}
   Ekos External Guide: ${LAN_IP}:${PHD2_PORT:-4400} (MaryGuider-RPZ2 retired)
======================================================================
EOF

if [[ "${ADA_REBOOT_REQUIRED:-false}" == "true" ]]; then
    printf '\n\033[1;33m[ACTION REQUIRED]\033[0m Boot parameters changed or cgroup memory controller not yet active.\n'
    printf '  Run:  sudo reboot\n'
    printf '  Then: sudo ada ort\n\n'
else
    printf '\nRun Day-0 Operational Readiness Test:\n  sudo ada ort\n\n'
fi
