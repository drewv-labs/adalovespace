#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#
echo "=== Nuking Bluetooth and Wi-Fi Radios"

sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now wpa_supplicant.service

sudo apt-mark unhold bluez wpasupplicant wireless-tools # Just in case
sudo apt purge bluez wpasupplicant wireless-tools -y
echo ""
