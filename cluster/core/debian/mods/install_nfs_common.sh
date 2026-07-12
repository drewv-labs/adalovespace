#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing NFS Common"

sudo apt install nfs-common -y
echo ""
