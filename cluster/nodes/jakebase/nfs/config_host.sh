#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

service_user_dir="/home/${ADA_USER}"
if [[ ! -e ${service_user_dir}/adalovespace ]]; then
    echo "FATAL: ${service_user_dir}/adalovespace does not exist"
    exit 1
fi

echo "=== Configuring JakeBase NFS Host"

sudo mkdir -p "${NFS_ROOT}"
sudo chown nobody:nogroup "${NFS_ROOT}"
sudo chmod 777 "${NFS_ROOT}"
safe-tee-sed "/etc/exports" "^${NFS_ROOT}" "${NFS_ROOT} *(rw,sync,no_subtree_check,all_squash,insecure)" "yes"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

sudo ln -s /home/${ADA_USER}/adalovespace "${NFS_CODE}/adalovespace"
echo ""
