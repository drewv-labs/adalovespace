#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_PLUM}=== Building Mosquitto Broker ==="

${ADA_CLUSTER}/core/debian/mods/install_mosquitto_broker.sh
${ADA_CLUSTER}/nodes/jakebase/mqtt/config_broker.sh
