#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaLovespace Declarative Node Harness & CLI (`ada`)
# Path: adalovespace/forge.sh
#
# Usage:
#   sudo ada init   [--role adactrl|jakebase|caroline-v|margistars|alonev-air]
#                   [--board rpi5|rv2|vf2|jptr2|n100] [--hostname <name>] [--force]
#   sudo ada forge  [--role <role>] [--board <board>] [--no-apt-update]
#                   [--rebuild-indi] [--rebuild-phd2] [--reset-indi-configs]
#   sudo ada status
#   sudo ada ort    [--stage <tag>] [--out-dir ~/.adalovespace/snapshots]
#   sudo ada verify [--no-apt-update]
#   sudo ada update [--skip-rvdk]
# ==============================================================================

if [[ -n "${ZSH_VERSION:-}" ]]; then
    emulate -L ksh
    setopt PIPE_FAIL ERR_RETURN NO_UNSET
else
    set -Eeuo pipefail
fi

SCRIPT_SELF="${BASH_SOURCE[0]:-}"

show_help() {
    cat <<'EOF'
DREW-V Labs // AdaLovespace CLI (`ada`)

Usage:
  sudo ada init   [--role <role>] [--board <board>] [--hostname <name>] [--force]
  sudo ada forge  [--no-apt-update] [--rebuild-indi] [--rebuild-phd2] [--reset-indi-configs]
  sudo ada status
  sudo ada ort    [--stage <tag>] [--out-dir <dir>]
  sudo ada verify [--no-apt-update]
  sudo ada update [--skip-rvdk]

Roles:
  adactrl      On-Scope INDI + Headless PHD2 + Pigeoneer (AdaCtrl-RPI5 / AdaCtrl-RV2)
  jakebase     AdaRak Data Broker (PostgreSQL 18.6 io_uring + Mosquitto + NFS-Ganesha + PigeonCoop)
  caroline-v   AdaRak Edge NPU Inference Engine (Hailo-8 / Hailo-10H + Pigeoneer)
  margistars   AdaRak Capture & Event Orchestration Maestro
  alonev-air   All-in-One RISC-V Scope Compute + Hailo-10H (Orange Pi RV2)

Boards:
  rpi5         Raspberry Pi 5 (BCM2712 4x Cortex-A76 + RP1, arm64)
  rv2          Orange Pi RV2 (SpacemiT Ky X1 8x X60, riscv64)
  vf2          StarFive VisionFive 2 (JH7110 4x U74, riscv64)
  jptr2        Milk-V Jupiter 2 (SpacemiT K3 8x X100, riscv64)
  n100         Intel N100 Mini PC (Alder Lake-N, amd64)
EOF
}

for _arg in "$@"; do
    if [[ "$_arg" == "-h" || "$_arg" == "--help" || "$_arg" == "help" ]]; then
        show_help
        exit 0
    fi
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    if [[ -n "$SCRIPT_SELF" && -f "$SCRIPT_SELF" ]] && command -v sudo >/dev/null 2>&1; then
        exec sudo -E bash "$SCRIPT_SELF" "$@"
    else
        echo "[ADA:FATAL] Run via sudo: sudo ada <init|forge|ort|status|verify|update>" >&2
        exit 1
    fi
fi

umask 022

if [[ -n "$SCRIPT_SELF" ]]; then
    SCRIPT_REAL="$(readlink -f "$SCRIPT_SELF" 2>/dev/null || realpath "$SCRIPT_SELF" 2>/dev/null || echo "$SCRIPT_SELF")"
    ADA_ENGINE_ROOT="$(cd "$(dirname "$SCRIPT_REAL")" && pwd)"
else
    ADA_ENGINE_ROOT="/opt/adalovespace/engine"
fi
export ADA_ENGINE_ROOT

# shellcheck source=lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ada_sanitize_locale
ada_resolve_caller

ADA_USER_DIR="${REAL_HOME}/.adalovespace"
NODE_ENV="${ADA_NODE_ENV:-${ADA_USER_DIR}/node.env}"
SNAP_DIR="${ADA_USER_DIR}/snapshots"
RVDK_BASE_URL="${RVDK_BASE_URL:-https://rvdk.drewv-labs.dev}"
ADA_BASE_URL="${ADA_BASE_URL:-https://adalovespace.dev}"

RVDK_BIN="/usr/local/bin/rvdk"
[[ ! -x "$RVDK_BIN" && -x /usr/bin/rvdk ]] && RVDK_BIN="/usr/bin/rvdk"
export RVDK_BIN

# ==============================================================================
# 1. Subcommand Dispatch
# ==============================================================================
ACTION=""
if [[ $# -gt 0 ]]; then
    case "$1" in
        init|forge|status|ort|verify|update|self-update)
            ACTION="$1"
            shift
            ;;
        --*)
            ACTION="forge"
            ;;
        *)
            log_fatal "Unknown subcommand '$1' (expected: init | forge | status | ort | verify | update)"
            ;;
    esac
else
    if [[ -f "$NODE_ENV" ]]; then
        ACTION="forge"
    else
        log_fatal "No node spec found at ${NODE_ENV}. Run 'sudo ada init' first, edit ${NODE_ENV}, then run 'sudo ada forge'."
    fi
fi

# ==============================================================================
# 2. Handle `update`
# ==============================================================================
if [[ "$ACTION" == "update" || "$ACTION" == "self-update" ]]; then
    SKIP_RVDK="false"
    QUIET_ARGS=()
    for uarg in "$@"; do
        case "$uarg" in
            --skip-rvdk) SKIP_RVDK="true" ;;
            -q|--quiet)  QUIET_ARGS+=("--quiet") ;;
        esac
    done

    if [[ "$SKIP_RVDK" != "true" && "$(uname -m)" == "riscv64" ]]; then
        if [[ -x "$RVDK_BIN" ]]; then
            "$RVDK_BIN" update --quiet
        else
            curl -fsSL "${RVDK_BASE_URL}/install-cli.sh" | bash -s -- --quiet
        fi
    fi

    if [[ -f "${ADA_ENGINE_ROOT}/install-cli.sh" ]]; then
        exec bash "${ADA_ENGINE_ROOT}/install-cli.sh" ${QUIET_ARGS[@]+"${QUIET_ARGS[@]}"}
    else
        curl -fsSL "${ADA_BASE_URL}/install-cli.sh" | bash -s -- ${QUIET_ARGS[@]+"${QUIET_ARGS[@]}"}
        exit 0
    fi
fi

# ==============================================================================
# 3. Handle `status`
# ==============================================================================
if [[ "$ACTION" == "status" ]]; then
    ada_detect_board
    log_ada "Host: $(hostname) | Board: ${ADA_DETECTED_BOARD:-unknown} (${ADA_DT_MODEL})"
    log_ada "Spec: ${NODE_ENV} ($( [[ -f "$NODE_ENV" ]] && echo "present" || echo "missing — run 'sudo ada init'" ))"
    printf '\n--- Cgroup v2 Controllers ---\n'
    cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null || echo "(unavailable)"
    printf '\n--- Slice AllowedCPUs ---\n'
    for sl in system.slice user.slice observability.slice indi.slice guiding.slice inference.slice; do
        if systemctl list-unit-files "$sl" >/dev/null 2>&1 || [[ "$sl" == "system.slice" || "$sl" == "user.slice" ]]; then
            printf '  %-22s AllowedCPUs=%s\n' "$sl" "$(systemctl show -p AllowedCPUs --value "$sl" 2>/dev/null || echo "-")"
        fi
    done
    printf '\n--- AdaCtrl Services ---\n'
    for svc in indiwebmanager.service xvfb-guiding.service phd2.service pigeoneer.service; do
        printf '  %-24s state=%-10s slice=%s\n' \
            "$svc" \
            "$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")" \
            "$(systemctl show -p Slice --value "$svc" 2>/dev/null || echo "-")"
    done
    printf '\n--- TCP Listeners (7624 / 8624 / 4400) ---\n'
    ss -tlnp 2>/dev/null | grep -E ':(7624|8624|4400)\b' || echo "  (none)"
    exit 0
fi

# ==============================================================================
# 4. Handle `ort` & `verify`
# ==============================================================================
if [[ "$ACTION" == "ort" ]]; then
    if [[ -f "$NODE_ENV" ]]; then
        ada_kv_load "$NODE_ENV"
    fi
    ada_detect_board
    BOARD_TAG="${BOARD_TAG:-${ADA_DETECTED_BOARD:-rpi5}}"
    [[ -f "${ADA_ENGINE_ROOT}/boards/${BOARD_TAG}.env" ]] && ada_kv_load "${ADA_ENGINE_ROOT}/boards/${BOARD_TAG}.env"
    [[ -f "$NODE_ENV" ]] && ada_kv_load "$NODE_ENV"
    export ADA_NODE_ENV="$NODE_ENV"
    export ADA_SNAP_DIR="$SNAP_DIR"
    exec bash "${ADA_ENGINE_ROOT}/scripts/ort-adactrl.sh" "$@"
fi

if [[ "$ACTION" == "verify" ]]; then
    export ADA_NODE_ENV="$NODE_ENV"
    export ADA_SNAP_DIR="$SNAP_DIR"
    exec bash "${ADA_ENGINE_ROOT}/scripts/verify-convergence.sh" "$@"
fi

# ==============================================================================
# 5. Parse Flags for `init` and `forge`
# ==============================================================================
CLI_ROLE=""
CLI_BOARD=""
CLI_HOSTNAME=""
CLI_USER=""
CLI_SUBNET=""
FORCE_INIT="false"
ADA_NO_APT_UPDATE="${ADA_NO_APT_UPDATE:-false}"
ADA_REBUILD_INDI="false"
ADA_REBUILD_PHD2="false"
ADA_RESET_INDI_CONFIGS="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --role)                 CLI_ROLE="${2:-}"; shift 2 ;;
        --board|--target)       CLI_BOARD="${2:-}"; shift 2 ;;
        --hostname)             CLI_HOSTNAME="${2:-}"; shift 2 ;;
        --user)                 CLI_USER="${2:-}"; shift 2 ;;
        --subnet)               CLI_SUBNET="${2:-}"; shift 2 ;;
        -f|--force)             FORCE_INIT="true"; shift ;;
        --no-apt-update|--skip-apt-update)
                                ADA_NO_APT_UPDATE="true"; shift ;;
        --rebuild-indi)         ADA_REBUILD_INDI="true"; shift ;;
        --rebuild-phd2)         ADA_REBUILD_PHD2="true"; shift ;;
        --reset-indi-configs)   ADA_RESET_INDI_CONFIGS="true"; shift ;;
        --noprogbar|--no-progbar)
                                export RVDK_NO_PROGBAR="1"; shift ;;
        *)
            log_fatal "Unknown option '$1' for 'ada ${ACTION}' (try --help)"
            ;;
    esac
done

export ADA_NO_APT_UPDATE ADA_REBUILD_INDI ADA_REBUILD_PHD2 ADA_RESET_INDI_CONFIGS

ada_detect_board
install -d -m 0750 -o "$REAL_USER" -g "$REAL_GRP" "$ADA_USER_DIR" "$SNAP_DIR"

# ==============================================================================
# 6. Handle `ada init` -> Generate `~/.adalovespace/node.env`
# ==============================================================================
if [[ "$ACTION" == "init" ]]; then
    if [[ -f "$NODE_ENV" && "$FORCE_INIT" != "true" ]]; then
        log_skip "Node spec already exists at ${NODE_ENV} (pass '--force' to regenerate)"
        log_info "Review ${NODE_ENV} and run 'sudo ada forge' to converge."
        exit 0
    fi

    RESOLVED_BOARD="$(ada_normalize_board "${CLI_BOARD:-${ADA_DETECTED_BOARD:-rpi5}}")"
    [[ -z "$RESOLVED_BOARD" ]] && log_fatal "Unsupported board '${CLI_BOARD:-$ADA_DETECTED_BOARD}' (expected: rpi5 | rv2 | vf2 | jptr2 | n100)"

    DEFAULT_ROLE="$(ada_infer_default_role "${CLI_HOSTNAME:-$(hostname 2>/dev/null || echo "")}" "$RESOLVED_BOARD")"
    RESOLVED_ROLE="$(ada_normalize_role "${CLI_ROLE:-$DEFAULT_ROLE}")"
    [[ -z "$RESOLVED_ROLE" ]] && log_fatal "Unsupported role '${CLI_ROLE:-$DEFAULT_ROLE}' (expected: adactrl | jakebase | caroline-v | margistars | alonev-air)"

    BOARD_ENV_FILE="${ADA_ENGINE_ROOT}/boards/${RESOLVED_BOARD}.env"
    ROLE_ENV_FILE="${ADA_ENGINE_ROOT}/roles/${RESOLVED_ROLE}.env"
    [[ -f "$BOARD_ENV_FILE" ]] || log_fatal "Board profile missing: ${BOARD_ENV_FILE}"
    [[ -f "$ROLE_ENV_FILE" ]] || log_fatal "Role profile missing: ${ROLE_ENV_FILE}"

    ada_kv_load "$BOARD_ENV_FILE"
    ada_kv_load "$ROLE_ENV_FILE"

    CUR_HOST="$(hostname 2>/dev/null || echo "")"
    if [[ -n "$CLI_HOSTNAME" ]]; then
        INIT_HOSTNAME="$CLI_HOSTNAME"
    elif [[ -n "$CUR_HOST" && "$CUR_HOST" != "localhost" && "$CUR_HOST" != "raspberrypi" ]]; then
        INIT_HOSTNAME="$CUR_HOST"
    else
        INIT_HOSTNAME="${RESOLVED_ROLE}-${RESOLVED_BOARD}"
    fi

    INIT_USER="${CLI_USER:-$REAL_USER}"
    INIT_SUBNET="${CLI_SUBNET:-$(ada_detect_subnet)}"

    # Preserve existing CarrierPigeons telemetry endpoint if already provisioned on node
    INIT_PIG_NODE_ID="${INIT_HOSTNAME}"
    INIT_PIG_BROKER="tcp://jakebase:1883"
    INIT_PIG_TAGS="${BOARD_ARCH},${RESOLVED_BOARD},${NODE_GROUP},${RESOLVED_ROLE}"
    INIT_PIG_USER=""
    INIT_PIG_PASS=""
    if [[ -r /etc/pigeons/pigeoneer.env ]]; then
        ada_kv_load /etc/pigeons/pigeoneer.env || true
        [[ -n "${PIGEONEER_NODE_ID:-}" ]] && INIT_PIG_NODE_ID="$PIGEONEER_NODE_ID"
        [[ -n "${PIGEONEER_BROKER_URL:-}" ]] && INIT_PIG_BROKER="$PIGEONEER_BROKER_URL"
        [[ -n "${PIGEONEER_TAGS:-}" ]] && INIT_PIG_TAGS="$PIGEONEER_TAGS"
        [[ -n "${PIGEONEER_MQTT_USERNAME:-}" ]] && INIT_PIG_USER="$PIGEONEER_MQTT_USERNAME"
        [[ -n "${PIGEONEER_MQTT_PASSWORD:-}" ]] && INIT_PIG_PASS="$PIGEONEER_MQTT_PASSWORD"
    fi

    if [[ "$RESOLVED_ROLE" == "adactrl" || "$RESOLVED_ROLE" == "alonev-air" ]]; then
        ada_atomic_write "$NODE_ENV" 0640 "${REAL_USER}:${REAL_GRP}" <<EOF
# ==============================================================================
# DREW-V Labs // AdaLovespace Node Spec (~/.adalovespace/node.env)
# Generated : $(date -u '+%Y-%m-%dT%H:%M:%SZ')
# Hardware  : ${ADA_DT_MODEL} (${RESOLVED_BOARD} / ${BOARD_ARCH})
# Converge  : sudo ada forge
# ==============================================================================
NODE_ROLE="${RESOLVED_ROLE}"
BOARD_TAG="${RESOLVED_BOARD}"
TARGET_HOSTNAME="${INIT_HOSTNAME}"
ADMIN_USER="${INIT_USER}"
ADA_SUBNET="${INIT_SUBNET}"
RVDK_TUNE_PROFILE="${RVDK_TUNE_PROFILE:-ai}"

# -- Feature Gates --
ENABLE_CGROUP_PARTITIONING="${ENABLE_CGROUP_PARTITIONING:-true}"
DECOMMISSION_MARYGUIDER="${DECOMMISSION_MARYGUIDER:-true}"
ENABLE_INDI="${ENABLE_INDI:-true}"
ENABLE_ZWO_ASI="${ENABLE_ZWO_ASI:-true}"
ENABLE_PHD2="${ENABLE_PHD2:-true}"
ENABLE_PIGEONEER="${ENABLE_PIGEONEER:-true}"

# -- Declarative systemd Cgroup v2 Core Partitioning (No isolcpus=) --
SLICE_SYSTEM_CPUS="${SLICE_SYSTEM_CPUS}"
SLICE_USER_CPUS="${SLICE_USER_CPUS}"
SLICE_OBSERVABILITY_CPUS="${SLICE_OBSERVABILITY_CPUS}"
SLICE_INDI_CPUS="${SLICE_INDI_CPUS}"
SLICE_GUIDING_CPUS="${SLICE_GUIDING_CPUS}"
SLICE_INFERENCE_CPUS="${SLICE_INFERENCE_CPUS:-}"

# -- INDI Server & Web Manager (AdaScope-8F4) --
INDI_PORT="${INDI_PORT:-7624}"
INDIWEB_PORT="${INDIWEB_PORT:-8624}"
INDI_RIG_PROFILE="${INDI_RIG_PROFILE:-Ada Lovespace Rig}"
SITE_LAT="32.78"
SITE_LON="263.20"
SITE_ELEV="130.0"

# -- Decoupled Headless Xvfb + PHD2 (guiding.slice) --
PHD2_PORT="${PHD2_PORT:-4400}"
PHD2_DISPLAY="${PHD2_DISPLAY:-:99}"
PHD2_SCREEN_GEOM="${PHD2_SCREEN_GEOM:-1280x800x24}"
PHD2_INDI_HOST="${PHD2_INDI_HOST:-127.0.0.1}"
PHD2_INDI_CAMERA="${PHD2_INDI_CAMERA:-ZWO CCD ASI220MM Mini}"
PHD2_INDI_MOUNT="${PHD2_INDI_MOUNT:-ZWO AM5 USB}"
PHD2_PIXEL_SIZE_UM="${PHD2_PIXEL_SIZE_UM:-4.0}"
PHD2_FOCAL_LENGTH_MM="${PHD2_FOCAL_LENGTH_MM:-300}"

# -- CarrierPigeons Edge Telemetry (observability.slice) --
PIGEONEER_NODE_ID="${INIT_PIG_NODE_ID}"
PIGEONEER_BROKER_URL="${INIT_PIG_BROKER}"
PIGEONEER_TAGS="${INIT_PIG_TAGS}"
PIGEONEER_MQTT_USERNAME="${INIT_PIG_USER}"
PIGEONEER_MQTT_PASSWORD="${INIT_PIG_PASS}"
EOF
    else
        ada_atomic_write "$NODE_ENV" 0640 "${REAL_USER}:${REAL_GRP}" <<EOF
# ==============================================================================
# DREW-V Labs // AdaLovespace Node Spec (~/.adalovespace/node.env)
# Generated : $(date -u '+%Y-%m-%dT%H:%M:%SZ')
# Hardware  : ${ADA_DT_MODEL} (${RESOLVED_BOARD} / ${BOARD_ARCH})
# Converge  : sudo ada forge
# ==============================================================================
NODE_ROLE="${RESOLVED_ROLE}"
BOARD_TAG="${RESOLVED_BOARD}"
TARGET_HOSTNAME="${INIT_HOSTNAME}"
ADMIN_USER="${INIT_USER}"
ADA_SUBNET="${INIT_SUBNET}"
RVDK_TUNE_PROFILE="${RVDK_TUNE_PROFILE:-data}"

# -- RVDK Storage & Data Services (AdaRak) --
NVME_DEV="${NVME_DEV:-/dev/nvme0n1}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/nvme_data}"
NFS_MOUNT_POINT="${NFS_MOUNT_POINT:-/mnt/adalovespace}"
ENABLE_POSTGRES="${ENABLE_POSTGRES:-false}"
ENABLE_MQTT_BROKER="${ENABLE_MQTT_BROKER:-false}"
MQTT_PORT="${MQTT_PORT:-1883}"
ENABLE_NFS_SERVER="${ENABLE_NFS_SERVER:-false}"
NFS_BACKEND="${NFS_BACKEND:-ganesha}"

# -- CarrierPigeons Telemetry --
ENABLE_PIGEONEER="${ENABLE_PIGEONEER:-true}"
PIGEONEER_NODE_ID="${INIT_PIG_NODE_ID}"
PIGEONEER_BROKER_URL="${INIT_PIG_BROKER}"
PIGEONEER_TAGS="${INIT_PIG_TAGS}"
PIGEONEER_MQTT_USERNAME="${INIT_PIG_USER}"
PIGEONEER_MQTT_PASSWORD="${INIT_PIG_PASS}"
EOF
    fi

    log_ok "Initialized node spec (${RESOLVED_ROLE} on ${RESOLVED_BOARD}): ${NODE_ENV}"
    cat <<EOF

Next Steps:
  1. Review and customize your node spec:
       \${EDITOR:-nano} ${NODE_ENV}
  2. Converge the node:
       sudo ada forge
  3. Validate Day-0 Operational Readiness:
       sudo ada ort
EOF
    exit 0
fi

# ==============================================================================
# 7. Handle `ada forge` -> Load Spec + Role/Board Profiles & Converge Node
# ==============================================================================
if [[ ! -f "$NODE_ENV" ]]; then
    log_fatal "Node spec missing at ${NODE_ENV}. Run 'sudo ada init' first, edit ${NODE_ENV}, then run 'sudo ada forge'."
fi

# Pre-read NODE_ROLE & BOARD_TAG from node.env so role/board defaults load underneath
ada_kv_load "$NODE_ENV"

RESOLVED_BOARD="$(ada_normalize_board "${CLI_BOARD:-${BOARD_TAG:-${ADA_DETECTED_BOARD:-rpi5}}}")"
[[ -z "$RESOLVED_BOARD" ]] && log_fatal "Invalid BOARD_TAG '${CLI_BOARD:-${BOARD_TAG:-}}' in ${NODE_ENV}"

RESOLVED_ROLE="$(ada_normalize_role "${CLI_ROLE:-${NODE_ROLE:-adactrl}}")"
[[ -z "$RESOLVED_ROLE" ]] && log_fatal "Invalid NODE_ROLE '${CLI_ROLE:-${NODE_ROLE:-}}' in ${NODE_ENV}"

BOARD_ENV_FILE="${ADA_ENGINE_ROOT}/boards/${RESOLVED_BOARD}.env"
ROLE_ENV_FILE="${ADA_ENGINE_ROOT}/roles/${RESOLVED_ROLE}.env"
[[ -f "$BOARD_ENV_FILE" ]] || log_fatal "Board profile missing: ${BOARD_ENV_FILE}"
[[ -f "$ROLE_ENV_FILE" ]] || log_fatal "Role profile missing: ${ROLE_ENV_FILE}"

# Layer 1: Board defaults -> Layer 2: Role defaults -> Layer 3: User node.env -> Layer 4: CLI flags
ada_kv_load "$BOARD_ENV_FILE"
ada_kv_load "$ROLE_ENV_FILE"
ada_kv_load "$NODE_ENV"

NODE_ROLE="$RESOLVED_ROLE"
BOARD_TAG="$RESOLVED_BOARD"
[[ -n "$CLI_HOSTNAME" ]] && TARGET_HOSTNAME="$CLI_HOSTNAME"
[[ -n "$CLI_USER" ]] && ADMIN_USER="$CLI_USER"
[[ -n "$CLI_SUBNET" ]] && ADA_SUBNET="$CLI_SUBNET"

ADMIN_USER="${ADMIN_USER:-$REAL_USER}"
TARGET_HOSTNAME="${TARGET_HOSTNAME:-${NODE_ROLE}-${BOARD_TAG}}"
ADA_SUBNET="${ADA_SUBNET:-10.42.0.0/24}"

export NODE_ROLE BOARD_TAG NODE_GROUP TARGET_HOSTNAME ADMIN_USER ADA_SUBNET
export ADA_NODE_ENV="$NODE_ENV"
export RVDK_ENV_FILE="$NODE_ENV"

log_ada "Forging ${TARGET_HOSTNAME} | Role: ${NODE_ROLE} (${NODE_GROUP}) | Board: ${BOARD_TAG} (${BOARD_ARCH}) | Spec: ${NODE_ENV}"

# Ensure RVDK is installed automatically when forging a native riscv64 board
if [[ "${BOARD_RVDK_NATIVE:-false}" == "true" && "$(uname -m)" == "riscv64" && ! -x "$RVDK_BIN" ]]; then
    log_step "0. Installing RVDK CLI (${RVDK_BASE_URL}/install-cli.sh)"
    curl -fsSL "${RVDK_BASE_URL}/install-cli.sh" | bash -s -- --quiet
    [[ -x /usr/bin/rvdk ]] && RVDK_BIN="/usr/bin/rvdk" || RVDK_BIN="/usr/local/bin/rvdk"
    export RVDK_BIN
fi

# Route `alonev-air` to `adactrl` scope builder with inference slice enabled
DISPATCH_DIR="${ADA_ENGINE_ROOT}/src/adastak/${NODE_GROUP}/nodes/${NODE_ROLE}"
if [[ "$NODE_ROLE" == "alonev-air" ]]; then
    DISPATCH_DIR="${ADA_ENGINE_ROOT}/src/adastak/adascope/nodes/adactrl"
fi

BUILD_ENTRYPOINT="${DISPATCH_DIR}/build.sh"
[[ -f "$BUILD_ENTRYPOINT" ]] || log_fatal "Node builder entrypoint missing: ${BUILD_ENTRYPOINT}"

exec bash "$BUILD_ENTRYPOINT"
