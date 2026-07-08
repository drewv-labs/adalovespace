#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#
echo "=== Installing NFS Kernel Server"

sudo apt install nfs-kernel-server -y
echo ""
