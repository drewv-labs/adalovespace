#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "sys" "=== Debian Base Installs"

if ! command -v uv &> /dev/null; then
    "${ADA_ROOT}/cluster/core/debian/mods/install_uv_root.sh"
fi
