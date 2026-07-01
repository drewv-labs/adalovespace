#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/install_telegraf.sh
${LIB}/jakebase/config_telegraf_daemon.sh
