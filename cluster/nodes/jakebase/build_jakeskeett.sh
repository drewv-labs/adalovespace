#!/bin/bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

cluster=${ADA_ROOT}/cluster

${cluster}/core/debian/mods/install_mosquitto_broker.sh
${cluster}/nodes/jakebase/mqtt/config_mosquitto_broker.sh
