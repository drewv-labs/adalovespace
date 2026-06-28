#!/bin/bash
#

source $HOME/adalovespace/cluster.conf

echo "=== Configuring JakeBase NFS Host"

mk_dir() {
  sudo mkdir -p "$1"
  sudo chown -R nobody:nogroup "$1"
  sudo chmod 777 "$1"
}

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  if ! grep -qF -- "$dir" /etc/exports; then
    echo "$dir $policy" >> /etc/exports
  fi
}

default_policy="*(rw,sync,no_subtree_check,all_squash,insecure)"

sudo mk_dir ${NFS_ADASPACE}
sudo add_nfs_config "${NFS_ADASPACE}" "$default_policy"

sudo mk_dir ${NFS_WHEELHOUSE}
sudo add_nfs_config "${NFS_WHEELHOUSE}" "$default_policy"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo ""
