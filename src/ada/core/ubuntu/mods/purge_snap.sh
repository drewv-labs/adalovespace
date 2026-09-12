#!/usr/bin/env bash

set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log mod "=== Purging Snap"

sudo systemctl disable --now snapd.socket snapd.service
sudo apt purge autoremove snapd
sudo apt-mark hold snapd
