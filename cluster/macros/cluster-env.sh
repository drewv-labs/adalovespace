#!/bin/bash
# Global Ada Lovespace Environment Resolver
# Must be invoked via: source /usr/local/bin/ada-env "${BASH_SOURCE[0]}"

# 1. Check for explicit environment override first (e.g., sandbox testing)
ENV_FILE="${ADALOVESPACE_CONF:-}"

# 2. Check the production baremetal anchor
if [[ -z "${ENV_FILE}" && -f "/opt/adalovespace/cluster.env" ]]; then
    ENV_FILE="/opt/adalovespace/cluster.env"
fi

# 3. Fallback: Walk UP the directory tree from the calling script's location
if [[ -z "${ENV_FILE}" || ! -f "${ENV_FILE}" ]]; then
    # Resolve the absolute path of the directory containing the calling script
    CURRENT_DIR="$(cd "$(dirname "${1:-$PWD}")" && pwd)"

    # Loop upward until we hit root or find cluster.env
    while [[ "${CURRENT_DIR}" != "/" ]]; do
        if [[ -f "${CURRENT_DIR}/cluster.env" ]]; then
            ENV_FILE="${CURRENT_DIR}/cluster.env"
            break
        fi
        CURRENT_DIR="$(dirname "${CURRENT_DIR}")"
    done
fi

# 4. Validate, safely toggle Nounset (-u), and source
if [[ -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
    echo "--- [ada-env] Sourcing configuration from: ${ENV_FILE}"
    set +u
    source "${ENV_FILE}"
    set -u
else
    echo "FATAL: [ada-env] Could not locate cluster.env in /opt/adalovespace or parent tree of ${1:-$PWD}" >&2
    return 1 2>/dev/null || exit 1
fi
