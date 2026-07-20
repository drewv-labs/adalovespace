#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "app" "=== Building INDI Web Server ==="

"${ADA_CLUSTER}/core/debian/mods/install_indi.sh"
