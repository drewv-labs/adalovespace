#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Nuking Wi-Fi Radios"

sudo systemctl disable --now wpa_supplicant.service
sudo apt-mark unhold wpasupplicant
sudo apt purge wpasupplicant

echo ""
