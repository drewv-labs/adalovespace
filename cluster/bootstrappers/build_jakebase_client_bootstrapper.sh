#!/bin/bash
set -euxo pipefall
source ada-sudo-check
if ! check_sudo_access; then
    echo "Aborting deployment"
    exit 1
fi

source ada-env "${BASH_SOURCE[0]}"

# Check if the node argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <node>"
    exit 1
fi

# Define variables based on the node argument
# This script assumes the node is a valid directory within /opt/ada-codespace/nodes/
# and that the bootstrapper.sh script exists in that directory.

node = $1

jake_repos = "/mnt/ada/codespace"

# 1. Mount the central file systems from JakeBase if not present
if ! mountpoint -q $jake_repos; then
    sudo mkdir -p $jake_repos
    sudo mount -t nfs 10.42.0.99:/mnt/export/repos $jake_repos
fi

# 2. Synchronize Code to Local Solid-State Runtime Mirror
# This is blistering fast and detaches runtime execution from network I/O
sudo mkdir -p /opt/ada-codespace
sudo rsync -aq --delete --progress ${jake_repos}/adalovespace/ ${code_space}
echo "Bootstrapper cloned from JakeBaseNFS"

# 3. Pivot Execution to Local Mirror Context
# Your scripts run with local IOPS speeds, completely immune to field network drops!
bootstrapper = "${code_space}/nodes/${node}/bootstrapper.sh"
echo "executing ${bootstrapper}"
exec $bootstrapper
