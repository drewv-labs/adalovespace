#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

if [[ ! -e "$ADA_CODESPACE" ]]; then
    ada-logger oof "FATAL: '$ADA_CODESPACE' does not exist"
    exit 1
fi

ada-logger mod "=== Configuring JakeBase NFS Host"

sudo mkdir -p "$NFS_ROOT"
sudo mkdir -p "$NFS_CODE"
sudo mkdir -p "$NFS_LOGS"
sudo mkdir -p "$NFS_SHARE"

sudo ln -s "$ADA_CODESPACE" "$NFS_CODE/adalovespace"

sudo chown -R nobody:nogroup "$NFS_ROOT"
sudo chmod -R 777 "$NFS_ROOT"

safe-tee-sed /etc/exports "^$NFS_ROOT" "$NFS_ROOT *(rw,sync,no_subtree_check,all_squash,insecure)" "yes"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server
