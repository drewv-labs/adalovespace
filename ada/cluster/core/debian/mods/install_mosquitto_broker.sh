#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Installing Mosquitto for Broker"

sudo apt install mosquitto mosquitto-clients -y
echo ""
