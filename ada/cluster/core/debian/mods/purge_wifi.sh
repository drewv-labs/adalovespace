#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Purging Wi-Fi Radios"

sudo systemctl disable --now wpa_supplicant.service
sudo apt-mark unhold wpasupplicant
sudo apt purge wpasupplicant
