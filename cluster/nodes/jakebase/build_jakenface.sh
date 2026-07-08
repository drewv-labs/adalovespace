#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

cluster=/opt/adalovespace/cluster

${cluster}/core/debian/mods/install_nfs_kernel_server.sh
${cluster}/nodes/jakebase/nfs/config_host.sh
