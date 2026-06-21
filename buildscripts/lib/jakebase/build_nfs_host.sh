#!/bin/bash
#
${HOME}/adalovespace/buildscripts/lib/debian/install_nfs_kernel_server.sh

echo "=== Building Jake's NFS Host"

SHAREDIR=/mnt/share
WHEELHOUSE=/mnt/wheelhouse

# Create NFS share directory
sudo mkdir -p ${SHAREDIR}
sudo chown -R nobody:nogroup ${SHAREDIR}
sudo chmod 777 ${SHAREDIR}
echo "${SHAREDIR} *(rw,sync,no_subtree_check,all_squash,insecure)" | sudo tee -a /etc/exports

# Create NFS wheelhouse directory
sudo mkdir -p ${WHEELHOUSE}
sudo chown -R nobody:nogroup ${WHEELHOUSE}
sudo chmod 777 ${WHEELHOUSE}
echo "${WHEELHOUSE} *(rw,sync,no_subtree_check,all_squash,insecure)" | sudo tee -a /etc/exports

# Reload NFS exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
