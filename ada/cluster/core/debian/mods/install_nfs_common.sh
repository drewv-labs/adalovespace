#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Installing NFS Common"

sudo apt install nfs-common -y
echo ""
