#!/bin/bash

source $HOME/adalovespace/cluster.conf

echo "=== Configuring JakeBase NFS Host"

sudo mkdir -p ${NFS_SHARE}
sudo chown -R nobody:nogroup ${NFS_SHARE}
sudo chmod 777 ${NFS_SHARE}
echo "${NFS_SHARE} *(rw,sync,no_subtree_check,all_squash,insecure)" | sudo tee -a /etc/exports

sudo mkdir -p ${NFS_WHEELHOUSE}
sudo chown -R nobody:nogroup ${NFS_WHEELHOUSE}
sudo chmod 777 ${NFS_WHEELHOUSE}
echo "${NFS_WHEELHOUSE} *(rw,sync,no_subtree_check,all_squash,insecure)" | sudo tee -a /etc/exports

sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo ""
