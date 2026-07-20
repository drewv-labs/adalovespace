#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Installing stress-ng"

sudo apt-get update -qq && sudo apt-get install -y -qq stress-ng

echo ""
