#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing NFS Kernel Server"

sudo apt install nfs-kernel-server -y
echo ""
