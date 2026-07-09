#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Nuking ModemManager"

sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y
echo ""
