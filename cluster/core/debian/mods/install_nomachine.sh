#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

source /opt/adalovespace/cluster.env

v_majmin="${NM_V_MAJOR}.${NM_V_MINOR}"
v_full="${NM_V_MAJOR}.${NM_V_MINOR}.${NM_V_PATCH}_${NM_V_BUILD}"

echo "=== Installing NoMachine"
wget https://download.nomachine.com/download/${v_majmin}/Linux/nomachine_${v_full}_amd64.deb
sudo dpkg -i nomachine_${v_full}_amd64.deb
echo ""
