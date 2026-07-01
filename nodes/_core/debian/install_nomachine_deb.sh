#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#
echo "=== Installing NoMachine"

wget https://download.nomachine.com/download/9.7/Linux/nomachine_9.7.3_1_amd64.deb
sudo dpkg -i nomachine_9.7.3_1_amd64.deb
echo ""
