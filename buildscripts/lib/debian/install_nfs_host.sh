#!/bin/bash
#
echo "=== Installing NFS Host"

sudo apt install nfs-kernel-server -y

# Create NFS share directory
sudo mkdir -p /mnt/share
sudo chown -R nobody:nogroup /mnt/share
sudo chmod 777 /mnt/share
echo "/mnt/share *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

# Create NFS wheelhouse directory
sudo mkdir -p /mnt/wheelhouse
sudo chown -R nobody:nogroup /mnt/wheelhouse
sudo chmod 777 /mnt/wheelhouse
echo "/mnt/wheelhouse *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports

# Reload NFS exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
