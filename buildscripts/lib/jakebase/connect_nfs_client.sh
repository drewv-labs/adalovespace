#!/bin/bash

source ${HOME}/adalovespace/cluster.conf

echo "=== Connecting JakeBase NFS as Client"
sudo mkdir -p $NFS_SHARE
sudo mkdir -p $NFS_WHEELHOUSE

echo "${JAKEBASE_IP}:${NFS_SHARE} ${NFS_SHARE} nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab
echo "${JAKEBASE_IP}:${NFS_WHEELHOUSE} ${NFS_WHEELHOUSE} nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a
echo ""
