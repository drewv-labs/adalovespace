#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

echo "=== Nuking Cloud Bloat"

sudo touch /etc/cloud/cloud-init.disabled
sudo apt purge cloud-init -y
sudo rm -rf /etc/cloud/ /var/lib/cloud/
echo ""
