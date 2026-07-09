#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Installing NFS Common"

sudo apt install nfs-common -y
echo ""
