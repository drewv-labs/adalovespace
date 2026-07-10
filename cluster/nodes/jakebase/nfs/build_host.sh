#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster="${ADA_ROOT}/cluster"

echo "${ADA_PLUM}=== Building NFS Host ==="

${cluster}/core/debian/mods/install_nfs_kernel_server.sh
${cluster}/nodes/jakebase/nfs/config_host.sh
