#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "=== Updating, Upgrading, & Cleaning Up APT Packages"
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean -y
echo ""
