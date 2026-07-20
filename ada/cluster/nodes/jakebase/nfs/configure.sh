#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

if [[ ! -e "${ADA_CODESPACE}" ]]; then
    ada-log "oof" "FATAL: '${ADA_CODESPACE}' does not exist"
    exit 1
fi

ada-log "mod" "=== Configuring JakeBase NFS Host"

sudo mkdir -p "${NFS_ROOT}"
sudo mkdir -p "${NFS_CODE}"
sudo mkdir -p "${NFS_LOGS}"
sudo mkdir -p "${NFS_SHARE}"
sudo mkdir -p "${NFS_WHEELHOUSE}"

sudo ln -s "${ADA_CODESPACE}" "${NFS_CODE}/adalovespace"

sudo chown -R nobody:nogroup "${NFS_ROOT}"
sudo chmod -R 777 "${NFS_ROOT}"

safe-tee-sed "/etc/exports" "^${NFS_ROOT}" "${NFS_ROOT} *(rw,sync,no_subtree_check,all_squash,insecure)" "yes"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

echo ""
