#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Installing PostgreSQL"

sudo apt install postgresql postgresql-contrib -y
echo ""
