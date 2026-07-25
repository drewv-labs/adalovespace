#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log mod "=== Purging Wi-Fi Radios"

sudo systemctl disable --now wpa_supplicant.service
sudo apt-mark unhold wpasupplicant
sudo apt purge wpasupplicant
