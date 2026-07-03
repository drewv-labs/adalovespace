#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

source /opt/adalovespace/cluster.conf
#
echo "=== Installing NoMachine"

wget https://download.nomachine.com/download/${NM_V_MAJMIN}/Linux/nomachine_${NM_V_FULL}_amd64.deb
sudo dpkg -i nomachine_${NM_V_FULL}_amd64.deb
echo ""
