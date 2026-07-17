#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Purging RPi Connect"

sudo apt purge rpi-connect rpi-connect-lite

echo ""
