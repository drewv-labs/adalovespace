#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log app "=== Building NFS Server ==="

"$ADA_CLUSTER/core/debian/mods/install_nfs_kernel_server.sh"
"$ADA_CLUSTER/nodes/jakebase/nfs/configure.sh"
