#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Installing Ntfy"

sudo apt install ntfy -y
echo ""
