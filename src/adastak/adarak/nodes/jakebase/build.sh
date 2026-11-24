#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // JakeBase Data Broker Convergence (`AdaRak` / `jakebase`)
# Path: adalovespace/src/adastak/adarak/nodes/jakebase/build.sh
#
# Description:
#   Converges `JakeBase-VF2` (or successor RISC-V data broker) via RVDK +
#   CarrierPigeons:
#     1. `rvdk day0` OS & silicon BSP normalization
#     2. `rvdk mods/nvme-4kn --with-nfs-lv` Dual-LVM 4Kn XFS + Btrfs NFS vault
#     3. `rvdk postgresql` (PostgreSQL 18.6 `io_uring` + Sv39 HugePages)
#     4. `rvdk mods/mosquitto` (Eclipse Mosquitto MQTT broker + Unix socket)
#     5. `rvdk mods/nfs-vault --backend ganesha` (NFS-Ganesha exports: fits/logs/share)
#     6. `rvdk deeptune --tune data`
#     7. `CarrierPigeons` (`pigeoneer` + `pigeoncoop`) telemetry broker
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/../../../../.." && pwd)}"

# shellcheck source=../../../../../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ADMIN_USER="${ADMIN_USER:?ADMIN_USER required}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:-jakebase}"
BOARD_TAG="${BOARD_TAG:-vf2}"
BOARD_ARCH="${BOARD_ARCH:-$(uname -m)}"
ADA_SUBNET="${ADA_SUBNET:-10.42.0.0/24}"
RVDK_TUNE_PROFILE="${RVDK_TUNE_PROFILE:-data}"

NVME_DEV="${NVME_DEV:-/dev/nvme0n1}"
VG_NAME="${VG_NAME:-vg_ada}"
LV_NAME="${LV_NAME:-lv_pgdata}"
NFS_LV_NAME="${NFS_LV_NAME:-lv_nfsvault}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/nvme_data}"
NFS_MOUNT_POINT="${NFS_MOUNT_POINT:-/mnt/adalovespace}"
FS_LABEL="${FS_LABEL:-ADA_PGDATA}"
NFS_FS_LABEL="${NFS_FS_LABEL:-ADA_NFSVAULT}"
MQTT_PORT="${MQTT_PORT:-1883}"
NFS_BACKEND="${NFS_BACKEND:-ganesha}"

RVDK_BIN="${RVDK_BIN:-/usr/local/bin/rvdk}"
[[ ! -x "$RVDK_BIN" && -x /usr/bin/rvdk ]] && RVDK_BIN="/usr/bin/rvdk"
[[ -x "$RVDK_BIN" ]] || log_fatal "RVDK CLI not found at ${RVDK_BIN}. Install RVDK first on riscv64."

APT_UPDATED="${ADA_NO_APT_UPDATE:-false}"
run_rvdk() {
    local subcmd="$1"
    shift
    if [[ "$APT_UPDATED" == "true" ]]; then
        "$RVDK_BIN" "$subcmd" --no-apt-update "$@"
    else
        "$RVDK_BIN" "$subcmd" "$@"
        APT_UPDATED="true"
    fi
}

log_step "1/7. RVDK Day-0 OS & Silicon BSP Convergence (${TARGET_HOSTNAME})"
run_rvdk day0 --user "$ADMIN_USER" --hostname "$TARGET_HOSTNAME" --nopasswd

log_step "2/7. RVDK Dual-LVM 4Kn NVMe Provisioning (${NVME_DEV} -> ${MOUNT_POINT} + ${NFS_MOUNT_POINT})"
if [[ -b "$NVME_DEV" ]]; then
    NVME_FLAGS=(--device "$NVME_DEV" --mount "$MOUNT_POINT" --vg "$VG_NAME" --lv "$LV_NAME" --label "$FS_LABEL")
    if [[ "${ENABLE_NFS_SERVER:-true}" == "true" ]]; then
        NVME_FLAGS+=(--with-nfs-lv --nfs-mount "$NFS_MOUNT_POINT" --nfs-lv "$NFS_LV_NAME" --nfs-label "$NFS_FS_LABEL")
    fi
    run_rvdk mods/nvme-4kn "${NVME_FLAGS[@]}"
else
    log_skip "Block device ${NVME_DEV} not present; skipping nvme-4kn provisioning"
fi

log_step "3/7. RVDK PostgreSQL 18.6 Convergence (io_uring + Sv39 HugePages)"
if [[ "${ENABLE_POSTGRES:-true}" == "true" ]]; then
    run_rvdk postgresql --data-mount "$MOUNT_POINT" --subnet "$ADA_SUBNET"
else
    log_skip "PostgreSQL skipped (ENABLE_POSTGRES=false)"
fi

log_step "4/7. RVDK Eclipse Mosquitto MQTT Broker (:${MQTT_PORT})"
if [[ "${ENABLE_MQTT_BROKER:-true}" == "true" ]]; then
    run_rvdk mods/mosquitto --port "$MQTT_PORT" --data-mount "$MOUNT_POINT"
else
    log_skip "Mosquitto skipped (ENABLE_MQTT_BROKER=false)"
fi

log_step "5/7. RVDK NFS-Ganesha Vault Exports (${NFS_MOUNT_POINT} -> ${ADA_SUBNET})"
if [[ "${ENABLE_NFS_SERVER:-true}" == "true" ]]; then
    run_rvdk mods/nfs-vault --subnet "$ADA_SUBNET" --data-mount "$MOUNT_POINT" --backend "$NFS_BACKEND"
    if mountpoint -q "$NFS_MOUNT_POINT" 2>/dev/null || [[ -d "$NFS_MOUNT_POINT" ]]; then
        for sub in fits logs share; do
            install -d -m 0775 -o "$ADMIN_USER" -g "$ADMIN_USER" "${NFS_MOUNT_POINT}/${sub}"
        done
        log_ok "Verified AdaStak vault directories (${NFS_MOUNT_POINT}/{fits,logs,share})"
    fi
else
    log_skip "NFS vault server skipped (ENABLE_NFS_SERVER=false)"
fi

log_step "6/7. RVDK Silicon DeepTune (${RVDK_TUNE_PROFILE})"
run_rvdk deeptune --tune "$RVDK_TUNE_PROFILE"

log_step "7/7. CarrierPigeons Telemetry (${TARGET_HOSTNAME})"
if [[ "${ENABLE_PIGEONEER:-true}" == "true" ]]; then
    if [[ -x /usr/local/bin/pigeoneer && -f /etc/systemd/system/pigeoneer.service ]]; then
        systemctl enable --now pigeoneer.service >/dev/null 2>&1 || true
        log_skip "pigeoneer.service already installed and active"
    else
        PIG_INSTALL_URL="${PIGEONEER_INSTALL_URL:-https://raw.githubusercontent.com/drewv-labs/carrierpigeons/main/deployments/install-pigeoneer.sh}"
        PIGEONEER_NODE_ID="${PIGEONEER_NODE_ID:-$TARGET_HOSTNAME}" \
        PIGEONEER_BROKER_URL="${PIGEONEER_BROKER_URL:-tcp://127.0.0.1:${MQTT_PORT}}" \
        PIGEONEER_TAGS="${PIGEONEER_TAGS:-${BOARD_ARCH},${BOARD_TAG},adarak,jakebase}" \
        PIGEONEER_MQTT_USERNAME="${PIGEONEER_MQTT_USERNAME:-}" \
        PIGEONEER_MQTT_PASSWORD="${PIGEONEER_MQTT_PASSWORD:-}" \
            bash -c "curl -fsSL '${PIG_INSTALL_URL}' | bash"
        log_ok "Installed CarrierPigeons pigeoneer on ${TARGET_HOSTNAME}"
    fi
else
    log_skip "CarrierPigeons pigeoneer skipped (ENABLE_PIGEONEER=false)"
fi

log_ok "JakeBase convergence complete (${TARGET_HOSTNAME})"
