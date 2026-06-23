#!/bin/bash

echo "=== Connecting JakeBase NFS as Client"

SHAREDIR=/mnt/share
WHEELHOUSE=/mnt/wheelhouse

sudo mkdir -p $SHAREDIR
sudo mkdir -p $WHEELHOUSE

echo "${JAKE_IP}:${SHAREDIR} ${SHAREDIR} nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab
echo "${JAKE_IP}:${WHEELHOUSE} ${WHEELHOUSE} nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a
echo ""
