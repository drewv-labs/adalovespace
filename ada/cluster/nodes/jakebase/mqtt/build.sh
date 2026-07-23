#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building Mosquitto Broker ==="

"$ADA_CLUSTER/core/debian/mods/install_mosquitto_broker.sh"
"$ADA_CLUSTER/nodes/jakebase/mqtt/configure.sh"
