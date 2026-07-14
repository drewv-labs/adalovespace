#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

# Check if the script received an argument
if [ $# -eq 0 ]; then
    ada-log "oof" "Expecting NFS mode arg; e.g. 'root', 'share', 'code', 'wheelhouse'"
    exit 1
fi

# 1. Extract the suffix (everything after the LAST underscore)
suffix="${1##*_}"

# 2. Convert to uppercase (Requires Bash 4.0+, which Ubuntu/RPi OS have natively)
suffix_upper="${suffix^^}"

# 3. The Switch (case) Statement
case "$suffix_upper" in
    "ROOT")
        nfs_dir=${NFS_ROOT}
        ;;

    "SHARE")
        nfs_dir=${NFS_SHARE}
        ;;

    "CODE")
        nfs_dir=${NFS_CODE}
        ;;

    "WHEELHOUSE")
        nfs_dir=${NFS_WHEELHOUSE}
        ;;

    *)
        echo "${ERR_RED}Unknown type: ${suffix}"
        exit 1
        ;;
esac

ada-log "app" "=== Connecting JakeBase NFS as Client"

sudo mkdir -p "$nfs_dir"
safe-tee-sed "/etc/fstab" "^${nfs_dir}" "${NFS_HOST}:${nfs_dir} ${nfs_dir} nfs rw,sync,no_subtree_check,all_squash,insecure 0 0" "yes"

sudo systemctl daemon-reload
sudo mount -a

echo ""
