#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/base_tune.sh
${LIB}/debian/base_installs.sh

${LIB}/jakebase/build_nfs_host.sh
${LIB}/jakebase/build_postgresql_host.sh
${LIB}/jakebase/build_mosquitto_broker.sh
${LIB}/jakebase/build_telegraf_daemon.sh

${LIB}/debian/apt_update_upgrade_slay.sh

sudo reboot
