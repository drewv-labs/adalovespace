#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger main "=== Building MarGo Stack (VNC)"

"$ADA_CLUSTER/core/debian/mods/install_vnc.sh"
"$ADA_CLUSTER/nodes/margaret/margo/configure.sh"
