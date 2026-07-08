#!/bin/bash
set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELATIVE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Hierarchical resolution: Env override -> Production /opt -> Local Git repo fallback
ENV_FILE="${ADALOVESPACE_CONF:-/opt/adalovespace/cluster.env}"
if [[ ! -f "${ENV_FILE}" ]]; then
    ENV_FILE="${RELATIVE_ROOT}/cluster.env"
fi

if [[ -f "${ENV_FILE}" ]]; then
    echo "--- Sourcing cluster configuration from: ${ENV_FILE}"
    # Temporarily disable '-u' during source in case .env has unassigned optional vars
    set +u
    source "${ENV_FILE}"
    set -u
else
    echo "FATAL: cluster.env not found in /opt/adalovespace or ${RELATIVE_ROOT}" >&2
    exit 1
fi
