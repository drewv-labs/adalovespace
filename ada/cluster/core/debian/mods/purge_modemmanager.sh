#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Purging ModemManager"

sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y
echo ""
