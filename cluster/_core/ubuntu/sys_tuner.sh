#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

NODES_CORE=/opt/ada-codespace/nodes/_core
DEB=${NODES_CORE}/debian
UBU=${NODES_CORE}/ubuntu

${DEB}/sys_tuner.sh
${UBU}/nuke_cloud_bloat.sh
${UBU}/nuke_snap.sh
