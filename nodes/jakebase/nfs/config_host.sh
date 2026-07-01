#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#

source $HOME/adalovespace/cluster.conf

echo "=== Configuring JakeBase NFS Host"

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  if ! grep -qF -- "$dir" /etc/exports; then
    echo "$dir $policy" | sudo tee -a /etc/exports
  fi
}

default_policy="*(rw,sync,no_subtree_check,all_squash,insecure)"

sudo mkdir -p "${NFS_ADASPACE}"
sudo chown -R nobody:nogroup "${NFS_ADASPACE}"
sudo chmod 777 "${NFS_ADASPACE}"
add_nfs_config "${NFS_ADASPACE}" "$default_policy"

sudo mkdir -p "${NFS_WHEELHOUSE}"
sudo chown -R nobody:nogroup "${NFS_WHEELHOUSE}"
sudo chmod 777 "${NFS_WHEELHOUSE}"
add_nfs_config "${NFS_WHEELHOUSE}" "$default_policy"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo ""
