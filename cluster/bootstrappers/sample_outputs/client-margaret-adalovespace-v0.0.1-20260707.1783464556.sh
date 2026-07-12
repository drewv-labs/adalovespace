#!/bin/bash
# This buildscript was generated at $(date)
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# 1. Mount the central file systems from JakeBase if not present
if ! mountpoint -q "/mnt/ada/code"; then
    sudo mkdir -p "/mnt/ada/code"
    sudo mount -t nfs "10.42.0.99:/mnt/ada/code" "/mnt/ada/code"
fi

# 2. Synchronize Code to Local Solid-State Runtime Mirror
sudo mkdir -p "/opt/adalovespace"
sudo rsync -aq --delete --progress "/mnt/ada/code/adalovespace/" "/opt/adalovespace/"
echo "Bootstrapper cloned from JakeBaseNFS"

# 3. Soft link libs and utils
sudo ln -s /opt/adalovespace/cluster/lib/ada-preflight.sh /usr/local/bin/ada-preflight
sudo ln -s /opt/adalovespace/cluster/lib/ada-preflight-nosudo.sh /usr/local/bin/ada-preflight-nosudo
sudo ln -s /opt/adalovespace/cluster/lib/safe-tee-sed.sh /usr/local/bin/safe-tee-sed

# 4. Pivot Execution to Local Mirror Context
buildscript="/opt/adalovespace/cluster/nodes/margaret/build_node.sh"
echo "Executing build script: ${buildscript}"
exec "${buildscript}"
