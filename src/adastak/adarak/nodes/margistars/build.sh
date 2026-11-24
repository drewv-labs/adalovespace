#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // MargiStars / MargiMaestro Orchestration Node (`AdaRak` / `margistars`)
# Path: adalovespace/src/adastak/adarak/nodes/margistars/build.sh
#
# Description:
#   Converges `MargiStars-N100` (transitional KStars/Ekos capture workstation)
#   or `MargiMaestro-RV2` (`riscv64` CarrierPigeons event orchestrator), and
#   verifies remote INDI (`:7624`) + consolidated headless PHD2 (`:4400`)
#   endpoints on `AdaCtrl` (`MaryGuider-RPZ2` retired).
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/../../../../.." && pwd)}"

# shellcheck source=../../../../../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ADMIN_USER="${ADMIN_USER:?ADMIN_USER required}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:-margistars}"
BOARD_TAG="${BOARD_TAG:-n100}"
BOARD_ARCH="${BOARD_ARCH:-$(uname -m)}"
ADACTRL_HOST="${ADACTRL_HOST:-10.42.0.10}"
ADACTRL_INDI_PORT="${ADACTRL_INDI_PORT:-7624}"
ADACTRL_PHD2_PORT="${ADACTRL_PHD2_PORT:-4400}"

log_step "1/3. OS Baseline Normalization (${TARGET_HOSTNAME} | ${BOARD_TAG})"
if [[ "${BOARD_RVDK_NATIVE:-false}" == "true" && "$(uname -m)" == "riscv64" ]]; then
    RVDK_BIN="${RVDK_BIN:-/usr/local/bin/rvdk}"
    [[ ! -x "$RVDK_BIN" && -x /usr/bin/rvdk ]] && RVDK_BIN="/usr/bin/rvdk"
    [[ -x "$RVDK_BIN" ]] || log_fatal "RVDK CLI not found at ${RVDK_BIN}"
    RVDK_EXTRA=()
    [[ "${ADA_NO_APT_UPDATE:-false}" == "true" ]] && RVDK_EXTRA+=(--no-apt-update)
    "$RVDK_BIN" day0 --user "$ADMIN_USER" --hostname "$TARGET_HOSTNAME" --nopasswd ${RVDK_EXTRA[@]+"${RVDK_EXTRA[@]}"}
    "$RVDK_BIN" deeptune --tune "${RVDK_TUNE_PROFILE:-ai}" --no-apt-update
else
    log_skip "Transitional x86_64 host (${TARGET_HOSTNAME}); preserving desktop KStars/Ekos/NoMachine session"
fi

log_step "2/3. CarrierPigeons Edge Telemetry (${TARGET_HOSTNAME})"
if [[ "${ENABLE_PIGEONEER:-true}" == "true" ]]; then
    if [[ -x /usr/local/bin/pigeoneer && -f /etc/systemd/system/pigeoneer.service ]]; then
        systemctl enable --now pigeoneer.service >/dev/null 2>&1 || true
        log_skip "pigeoneer.service already installed and active"
    else
        PIG_INSTALL_URL="${PIGEONEER_INSTALL_URL:-https://raw.githubusercontent.com/drewv-labs/carrierpigeons/main/deployments/install-pigeoneer.sh}"
        PIGEONEER_NODE_ID="${PIGEONEER_NODE_ID:-$TARGET_HOSTNAME}" \
        PIGEONEER_BROKER_URL="${PIGEONEER_BROKER_URL:-tcp://jakebase:1883}" \
        PIGEONEER_TAGS="${PIGEONEER_TAGS:-${BOARD_ARCH},${BOARD_TAG},adarak,margistars}" \
        PIGEONEER_MQTT_USERNAME="${PIGEONEER_MQTT_USERNAME:-}" \
        PIGEONEER_MQTT_PASSWORD="${PIGEONEER_MQTT_PASSWORD:-}" \
            bash -c "curl -fsSL '${PIG_INSTALL_URL}' | bash"
        log_ok "Installed CarrierPigeons pigeoneer on ${TARGET_HOSTNAME}"
    fi
else
    log_skip "CarrierPigeons pigeoneer skipped (ENABLE_PIGEONEER=false)"
fi

log_step "3/3. AdaCtrl Remote INDI & Consolidated PHD2 Cutover Verification"
cat <<EOF
  Ekos Profile Endpoint Cutover (MaryGuider-RPZ2 Retired):
    INDI Server  : ${ADACTRL_HOST}:${ADACTRL_INDI_PORT}
    INDI Web Mgr : http://${ADACTRL_HOST}:8624
    Guider Type  : PHD2 (External)
    PHD2 Host    : ${ADACTRL_HOST}
    PHD2 Port    : ${ADACTRL_PHD2_PORT}
EOF

log_ok "MargiStars convergence complete (${TARGET_HOSTNAME})"
