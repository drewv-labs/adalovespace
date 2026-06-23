#!/bin/bash

echo "=== Configuring JakeBase NFS Host"

SHAREDIR=/mnt/share
sudo mkdir -p ${SHAREDIR}
sudo chown -R nobody:nogroup ${SHAREDIR}
sudo chmod 777 ${SHAREDIR}
echo "${SHAREDIR} *(rw,sync,no_subtree_check,all_squash,insecure)" | sudo tee -a /etc/exports

WHEELHOUSE=/mnt/wheelhouse
sudo mkdir -p ${WHEELHOUSE}
sudo chown -R nobody:nogroup ${WHEELHOUSE}
sudo chmod 777 ${WHEELHOUSE}
echo "${WHEELHOUSE} *(rw,sync,no_subtree_check,all_squash,insecure)" | sudo tee -a /etc/exports

sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo ""
