#!/bin/bash
#
add_nfs_config() {
  local dir="$1"
  local policy="$2"

  if ! grep -qF -- "$dir" /etc/exports; then
    echo "$dir $policy" >> /etc/exports
  fi
}

source $HOME/adalovespace/cluster.conf

echo "=== Configuring JakeBase NFS Host"

sudo mkdir -p ${NFS_SHARE}
sudo chown -R nobody:nogroup ${NFS_SHARE}
sudo chmod 777 ${NFS_SHARE}
add_nfs_config "${NFS_SHARE}" "*(rw,sync,no_subtree_check,all_squash,insecure)"

sudo mkdir -p ${NFS_WHEELHOUSE}
sudo chown -R nobody:nogroup ${NFS_WHEELHOUSE}
sudo chmod 777 ${NFS_WHEELHOUSE}
add_nfs_config "${NFS_WHEELHOUSE}" "*(rw,sync,no_subtree_check,all_squash,insecure)"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server
echo ""
