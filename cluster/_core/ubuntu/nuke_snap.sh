#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "=== Purging Snap"

sudo systemctl disable --now snapd.socket snapd.service

sudo apt purge autoremove snapd
sudo apt-mark hold snapd
echo ""
