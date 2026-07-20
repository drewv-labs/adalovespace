#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Purging Snap"

sudo systemctl disable --now snapd.socket snapd.service
sudo apt purge autoremove snapd
sudo apt-mark hold snapd

echo ""
