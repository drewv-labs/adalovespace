#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Installing PostgreSQL"

sudo apt install postgresql postgresql-contrib -y
echo ""
