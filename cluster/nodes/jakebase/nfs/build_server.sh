#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "app" "=== Building NFS Host ==="

${ADA_CLUSTER}/core/debian/mods/install_nfs_kernel_server.sh
${ADA_CLUSTER}/nodes/jakebase/nfs/config_host.sh
