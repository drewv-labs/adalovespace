#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/base_tune.sh
${LIB}/ubuntu/base_tune.sh
${LIB}/debian/base_installs.sh

${LIB}/connect_jakebase_client.sh

${LIB}/debian/build_debian_xfce_lightdm.sh
${LIB}/debian/install_nomachine_deb.sh
${LIB}/ubuntu/install_kstars_ekos.sh

${LIB}/debian/apt_update_upgrade_slay.sh

sudo reboot
