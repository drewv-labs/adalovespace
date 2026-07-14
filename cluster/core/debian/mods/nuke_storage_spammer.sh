#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Purging Storage Spammer"

sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
echo ""
