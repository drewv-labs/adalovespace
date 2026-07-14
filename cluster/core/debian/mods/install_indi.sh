#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Installing INDI Web Server"

sudo apt install indi-full -y
echo ""
