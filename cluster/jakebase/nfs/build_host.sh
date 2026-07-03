#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

NODES=/opt/adalovespace/nodes

${NODES}/_core/debian/install_nfs_kernel_server.sh
${NODES}/jakebase/config_nfs_host.sh
