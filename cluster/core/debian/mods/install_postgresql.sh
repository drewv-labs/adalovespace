#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing PostgreSQL"

sudo apt install postgresql postgresql-contrib -y
echo ""
