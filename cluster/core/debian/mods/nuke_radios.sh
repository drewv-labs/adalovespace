#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Nuking Bluetooth and Wi-Fi Radios"

sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now wpa_supplicant.service

sudo apt-mark unhold bluez wpasupplicant wireless-tools # Just in case
sudo apt purge bluez wpasupplicant wireless-tools -y
echo ""
