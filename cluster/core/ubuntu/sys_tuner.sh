#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

cluser_core=/opt/adalovespace/cluster/_core
deb=${cluser_core}/debian
ubu=${cluser_core}/ubuntu

${deb}/sys_tuner.sh
${ubu}/mods/nuke_cloud_bloat.sh
${ubu}/mods/nuke_snap.sh
