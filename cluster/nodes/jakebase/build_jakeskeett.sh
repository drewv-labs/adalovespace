#!/bin/bash
set -euxo pipefail
source sudo-check

cluster=/opt/adalovespace/cluster

${cluster}/core/debian/mods/install_mosquitto_broker.sh
${cluster}/nodes/jakebase/mqtt/config_mosquitto_broker.sh
