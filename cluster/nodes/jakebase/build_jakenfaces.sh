#!/bin/bash
set -euxo pipefail
source sudo-check

cluster=/opt/adalovespace/cluster

${cluster}/core/debian/mods/install_nfs_kernel_server.sh
${cluster}/nodes/jakebase/nfs/config_host.sh
