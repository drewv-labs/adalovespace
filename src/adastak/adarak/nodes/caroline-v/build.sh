#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // Caroline-V Edge NPU Inference Convergence (`AdaRak` / `caroline-v`)
# Path: adalovespace/src/adastak/adarak/nodes/caroline-v/build.sh
#
# Description:
#   Converges `CarolineV-VF2` (StarFive VisionFive 2 + Hailo-8 M.2 NPU) via
#   RVDK Day-0 + DeepTune (`--tune ai`) + CarrierPigeons (`pigeoneer`).
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/../../../../.." && pwd)}"

# shellcheck source=../../../../../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ADMIN_USER="${ADMIN_USER:?ADMIN_USER required}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:-caroline-v}"
BOARD_TAG="${BOARD_TAG:-vf2}"
BOARD_ARCH="${BOARD_ARCH:-$(uname -m)}"
RVDK_TUNE_PROFILE="${RVDK_TUNE_PROFILE:-ai}"

RVDK_BIN="${RVDK_BIN:-/usr/local/bin/rvdk}"
[[ ! -x "$RVDK_BIN" && -x /usr/bin/rvdk ]] && RVDK_BIN="/usr/bin/rvdk"
[[ -x "$RVDK_BIN" ]] || log_fatal "RVDK CLI not found at ${RVDK_BIN}. Install RVDK first on riscv64."

RVDK_EXTRA=()
[[ "${ADA_NO_APT_UPDATE:-false}" == "true" ]] && RVDK_EXTRA+=(--no-apt-update)

log_step "1/3. RVDK Day-0 OS & Silicon BSP Convergence (${TARGET_HOSTNAME})"
"$RVDK_BIN" day0 --user "$ADMIN_USER" --hostname "$TARGET_HOSTNAME" --nopasswd ${RVDK_EXTRA[@]+"${RVDK_EXTRA[@]}"}

log_step "2/3. RVDK Silicon DeepTune (${RVDK_TUNE_PROFILE})"
"$RVDK_BIN" deeptune --tune "$RVDK_TUNE_PROFILE" --no-apt-update

log_step "3/3. CarrierPigeons Edge Telemetry (${TARGET_HOSTNAME})"
if [[ "${ENABLE_PIGEONEER:-true}" == "true" ]]; then
    if [[ -x /usr/local/bin/pigeoneer && -f /etc/systemd/system/pigeoneer.service ]]; then
        systemctl enable --now pigeoneer.service >/dev/null 2>&1 || true
        log_skip "pigeoneer.service already installed and active"
    else
        PIG_INSTALL_URL="${PIGEONEER_INSTALL_URL:-https://raw.githubusercontent.com/drewv-labs/carrierpigeons/main/deployments/install-pigeoneer.sh}"
        PIGEONEER_NODE_ID="${PIGEONEER_NODE_ID:-$TARGET_HOSTNAME}" \
        PIGEONEER_BROKER_URL="${PIGEONEER_BROKER_URL:-tcp://jakebase:1883}" \
        PIGEONEER_TAGS="${PIGEONEER_TAGS:-${BOARD_ARCH},${BOARD_TAG},adarak,caroline-v}" \
        PIGEONEER_MQTT_USERNAME="${PIGEONEER_MQTT_USERNAME:-}" \
        PIGEONEER_MQTT_PASSWORD="${PIGEONEER_MQTT_PASSWORD:-}" \
        PIGEONEER_ENABLE_GPU_GROUPS="true" \
            bash -c "curl -fsSL '${PIG_INSTALL_URL}' | bash"
        log_ok "Installed CarrierPigeons pigeoneer on ${TARGET_HOSTNAME}"
    fi
else
    log_skip "CarrierPigeons pigeoneer skipped (ENABLE_PIGEONEER=false)"
fi

if command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -qi 'hailo'; then
    log_ok "Detected PCIe Hailo NPU accelerator on ${TARGET_HOSTNAME}"
else
    log_info "Hailo PCIe NPU check: verify M.2 link via 'lspci -nn | grep -i hailo'"
fi

log_ok "Caroline-V convergence complete (${TARGET_HOSTNAME})"
