#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

source ${HOME}/adalovespace/cluster.conf

default_config="nfs defaults,bg,noatime,nolock 0 0"

echo "=== Connecting JakeBase NFS as Client"
sudo mkdir -p $NFS_ADASPACE
sudo mkdir -p $NFS_WHEELHOUSE

echo "${JAKEBASE_IP}:${NFS_ADASPACE} ${NFS_ADASPACE} ${default_config}" | sudo tee -a /etc/fstab
echo "${JAKEBASE_IP}:${NFS_WHEELHOUSE} ${NFS_WHEELHOUSE} ${default_config}" | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a
echo ""
