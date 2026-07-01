#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

NODES=/opt/adalovespace/nodes

${NODES}/_core/debian/install_mosquitto_broker.sh
${LIB}/jakebase/mqtt/config_mosquitto_broker.sh
