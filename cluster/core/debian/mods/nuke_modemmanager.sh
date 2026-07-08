#!/bin/bash
set -euxo pipefail
source sudo-check

echo "=== Nuking ModemManager"

sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y
echo ""
