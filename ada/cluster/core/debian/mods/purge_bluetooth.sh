#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log mod "=== Purging Bluetooth Radios"

sudo systemctl disable --now bluetooth.service
sudo apt-mark unhold bluez
sudo apt purge bluez
