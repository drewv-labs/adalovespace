#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log app "=== Building Ntfy Server ==="

"$ADA_CLUSTER/core/debian/mods/install_ntfy.sh"
