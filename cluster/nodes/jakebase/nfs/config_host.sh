#!/bin/bash
set -euxo pipefail
source sudo-check
source ada-env ${BASH_SOURCE[0]}
source safe-tee-sed

echo "=== Configuring JakeBase NFS Host"

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  sudo mkdir -p "$dir"
  sudo chown nobody:nogroup "$dir"
  sudo chmod 777 "$dir"
  safe_tee_sed "/etc/exports" "^${dir}" "${dir} ${policy}" "yes"
}

add_nfs_config "${NFS_ROOT}" "*(rw,sync,no_subtree_check,all_squash,insecure)"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

sudo ln -s /home/${ADA_USER}/adalovespace "${NFS_CODE}/adalovespace"
echo ""
