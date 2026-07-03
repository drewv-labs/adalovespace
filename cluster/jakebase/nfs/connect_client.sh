#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check if the script received an argument
if [ $# -eq 0 ]; then
    echo "Expecting NFS mode arg; e.g. 'ROOT', 'SHARE', 'CODE', 'WHEELHOUSE'"
    exit 1
fi

# 1. Extract the suffix (everything after the LAST underscore)
suffix="${1##*_}"

# 2. Convert to uppercase (Requires Bash 4.0+, which Ubuntu/RPi OS have natively)
suffix_upper="${suffix^^}"

# 3. The Switch (case) Statement
case "$suffix_upper" in
    "ROOT")
        nfs=${NFS_ROOT}
        ;;

    "SHARE")
        echo "Executing SHARE logic..."
        ;;

    "CODE")
        echo "Executing CODE logic..."
        ;;

    "WHEELHOUSE")
        echo "Executing CODE logic..."
        ;;

    *)
        echo "Unknown type: ${suffix}"
        ;;
esac
source /opt/adalovespace/cluster.conf

default_config="nfs defaults,bg,noatime,nolock 0 0"

add_nfs_config() {
  local dir="$1"
  local policy="$2"
  if ! grep -qF -- "$dir" /etc/fstab; then
    echo "${JAKEBASE_IP}:${dir} ${dir} ${policy}" | sudo tee -a /etc/fstab
    echo "Added JakeBaseNFS config for $dir with policy: $policy"
  else
    echo "NFS export already exists for $dir"
  fi
}

echo "=== Connecting JakeBase NFS as Client"
sudo mkdir -p $NFS_ROOT

add_nfs_config $NFS_ROOT $default_config

sudo systemctl daemon-reload
sudo mount -a
echo ""
