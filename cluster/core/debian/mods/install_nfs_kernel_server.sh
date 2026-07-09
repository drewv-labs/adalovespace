#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Installing NFS Kernel Server"

sudo apt install nfs-kernel-server -y
echo ""
