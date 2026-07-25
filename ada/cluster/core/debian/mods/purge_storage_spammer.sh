#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger mod "=== Purging Multipathd Storage Spammer"

sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
