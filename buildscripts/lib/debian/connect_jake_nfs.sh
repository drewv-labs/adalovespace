#!/bin/bash
#
echo "=== Connecting Jake's NFS"

sudo mkdir -p /mnt/share
sudo mkdir -p /mnt/wheelhouse

sudo apt install nfs-common -y

echo "{$JAKE_IP}:/mnt/adaspace_share /mnt/share nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab
echo "{$JAKE_IP}:/mnt/wheelhouse /mnt/wheelhouse nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a
echo ""
