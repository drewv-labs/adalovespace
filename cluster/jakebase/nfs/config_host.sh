#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#

source /opt/adalovespace/cluster.conf

echo "=== Configuring JakeBase NFS Host"

mk_new_mnt() {
    local dir="$1"
    sudo mkdir -p "$dir"
    sudo chown nobody:nogroup "$dir"
    sudo chmod 777 "$dir"
}

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  mk_new_mnt "$dir"
  if ! grep -qF -- "$dir" /etc/exports; then
    echo "$dir $policy" | sudo tee -a /etc/exports
  fi
}

default_policy="*(rw,sync,no_subtree_check,all_squash,insecure)"

add_nfs_config "${NFS_ROOT}" "${default_policy}"
# add_nfs_config "${NFS_ADASPACE}" "${default_policy}"
# add_nfs_config "${NFS_CODESPACE}" "${default_policy}"
# add_nfs_config "${NFS_WHEELHOUSE}" "${default_policy}"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

sudo ln -s /home/drew/adalovespace /mnt/
echo ""
