#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger mod "=== Purging Unattended Upgrades Service"

sudo systemctl disable --now unattended-upgrades.service
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now apt-daily-upgrade.timer
