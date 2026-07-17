#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "app" "=== Building Ntfy Server ==="

"${ADA_CLUSTER}/core/debian/mods/install_ntfy.sh"
# ${ADA_CLUSTER}/nodes/jakebase/ntfy/config_server.sh
