#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check if the script received an argument
if [ $# -eq 0 ]; then
    echo "Expecting NFS mode arg; e.g. 'root', 'share', 'code', 'wheelhouse'"
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
        echo "Unknown type: ${suffix}"
        exit 1
        ;;
esac

source /opt/adalovespace/cluster.env

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  if ! grep -qF -- "$dir" /etc/fstab; then
    echo "${NFS_HOST}:${dir} ${dir} nfs ${policy} 0 0" | sudo tee -a /etc/fstab
    echo "Added ${NFS_HOST}:${dir} $policy to /etc/fstab"
  else
    echo "NFS export already exists for ${dir}; skipping"
  fi
}

echo "=== Connecting JakeBase NFS as Client"
sudo mkdir -p $nfs

add_nfs_config $nfs "defaults,bg,noatime,nolock"

sudo systemctl daemon-reload
sudo mount -a
echo ""
