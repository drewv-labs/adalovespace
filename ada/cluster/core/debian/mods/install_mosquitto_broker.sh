#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log mod "=== Installing Mosquitto for Broker"

sudo apt install mosquitto -y

# Enable and start the broker service
sudo systemctl enable --now mosquitto
