#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Disabling Unattended Upgrades Service"

sudo systemctl disable --now unattended-upgrades.service
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now apt-daily-upgrade.timer
echo ""
