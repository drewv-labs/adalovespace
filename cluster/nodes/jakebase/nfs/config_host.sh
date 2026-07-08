#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#

source /opt/adalovespace/cluster.env

echo "=== Configuring JakeBase NFS Host"

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  sudo mkdir -p "$dir"
  sudo chown nobody:nogroup "$dir"
  sudo chmod 777 "$dir"
  if ! grep -qF -- "$dir" /etc/exports; then
    echo "$dir $policy" | sudo tee -a /etc/exports
  else
      echo "!!! ${dir} already exists in exports file. Skipping... "
  fi
}

add_nfs_config "${NFS_ROOT}" "*(rw,sync,no_subtree_check,all_squash,insecure)"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

sudo ln -s /home/${ADA_USER}/adalovespace "${NFS_CODE}/adalovespace"
echo ""
