#!/bin/bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Mount the central file systems from JakeBase if not present
if ! mountpoint -q "/mnt/ada/code"; then
    sudo mkdir -p "/mnt/ada/code"
    sudo mount -t nfs "10.42.0.99:/mnt/ada/code" "/mnt/ada/code"
fi

# 2. Synchronize Code to Local Solid-State Runtime Mirror
# This detaches runtime execution from network I/O
sudo mkdir -p "/opt/adalovespace"
sudo rsync -aq --delete --progress "/mnt/ada/code/adalovespace/" "/opt/adalovespace"
echo "Bootstrapper cloned from JakeBaseNFS"

# 3. Soft link libs
if [[ ! -f "/usr/local/bin/ada-preflight" ]]; then
    sudo ln -s "/opt/adalovespace/cluster/lib/ada-preflight.sh" "/usr/local/bin/ada-preflight"
fi
if [[ ! -f "/usr/local/bin/ada-preflight-nosudo" ]]; then
    sudo ln -s "/opt/adalovespace/cluster/lib/ada-preflight-nosudo.sh" "/usr/local/bin/ada-preflight-nosudo"
fi
if [[ ! -f "/usr/local/bin/safe-tee-sed" ]]; then
    sudo ln -s "/opt/adalovespace/cluster/lib/safe-tee-sed.sh" "/usr/local/bin/safe-tee-sed"
fi

# 4. Pivot Execution to Local Mirror Context
# Your scripts run with local IOPS speeds, completely immune to field network drops!
buildscript="/opt/adalovespace/cluster/nodes/margaret/build_node.sh"
echo "executing ${buildscript}"
exec "${buildscript}"
