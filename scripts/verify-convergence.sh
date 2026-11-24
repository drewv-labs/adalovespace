#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaLovespace Convergence & Idempotency Validation Harness
# Path: adalovespace/scripts/verify-convergence.sh
#
# Description:
#   Executes back-to-back two-pass convergence (`ada forge` Pass 1 -> Pass 2)
#   and asserts zero unintended service restarts on Pass 2, followed by the
#   Day-0 Operational Readiness Test (`scripts/ort-adactrl.sh`).
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

# shellcheck source=../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ada_sanitize_locale
ada_resolve_caller

NODE_ENV="${ADA_NODE_ENV:-${REAL_HOME}/.adalovespace/node.env}"
[[ -f "$NODE_ENV" ]] || log_fatal "Node spec missing at ${NODE_ENV}. Run 'sudo ada init' first."
ada_kv_load "$NODE_ENV"

FORGE_ARGS=()
for arg in "$@"; do
    case "$arg" in
        --no-apt-update|--skip-apt-update) FORGE_ARGS+=("--no-apt-update") ;;
        -h|--help)
            cat <<'EOF'
Usage:
  sudo ada verify [--no-apt-update]
EOF
            exit 0
            ;;
        *) log_fatal "Unknown option '$1' for verify-convergence.sh" ;;
    esac
done

log_step "Pass 1/3: Primary Convergence (ada forge)"
bash "${ADA_ENGINE_ROOT}/forge.sh" forge ${FORGE_ARGS[@]+"${FORGE_ARGS[@]}"}

# Record service MainPIDs before Pass 2 to prove zero unintended restarts
declare -A PRE_PIDS=()
for svc in indiwebmanager.service xvfb-guiding.service phd2.service pigeoneer.service; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        PRE_PIDS["$svc"]="$(systemctl show -p MainPID --value "$svc" 2>/dev/null || echo "0")"
    fi
done

log_step "Pass 2/3: Idempotency Re-Run Validation (ADA_NO_APT_UPDATE=true)"
ADA_NO_APT_UPDATE="true" bash "${ADA_ENGINE_ROOT}/forge.sh" forge --no-apt-update

DRIFT_RESTARTS=0
for svc in "${!PRE_PIDS[@]}"; do
    post_pid="$(systemctl show -p MainPID --value "$svc" 2>/dev/null || echo "0")"
    if [[ "${PRE_PIDS[$svc]}" != "$post_pid" ]]; then
        log_fail "Idempotency violation: ${svc} restarted on Pass 2 (PID ${PRE_PIDS[$svc]} -> ${post_pid})"
        DRIFT_RESTARTS=$((DRIFT_RESTARTS + 1))
    else
        log_ok "Idempotency verified: ${svc} MainPID=${post_pid} unchanged across Pass 2"
    fi
done

if [[ "$DRIFT_RESTARTS" -gt 0 ]]; then
    log_fatal "${DRIFT_RESTARTS} service(s) restarted unexpectedly during Pass 2 idempotency validation"
fi

if [[ "${NODE_ROLE:-adactrl}" == "adactrl" || "${NODE_ROLE:-}" == "alonev-air" ]]; then
    log_step "Pass 3/3: Day-0 Operational Readiness Test (ort-adactrl.sh)"
    bash "${ADA_ENGINE_ROOT}/scripts/ort-adactrl.sh" --stage "verify-post-forge"
else
    log_skip "Role '${NODE_ROLE:-}' does not use AdaCtrl ORT; two-pass convergence verified"
fi
