#!/bin/bash

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
