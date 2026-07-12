#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Nuking ModemManager"

sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y
echo ""
