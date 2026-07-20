#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Installing NFS Kernel Server"

sudo apt install nfs-kernel-server -y
echo ""
