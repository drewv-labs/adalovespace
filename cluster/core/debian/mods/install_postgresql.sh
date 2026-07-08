#!/bin/bash
set -euxo pipefail
source sudo-check

echo "=== Installing PostgreSQL"

sudo apt install postgresql postgresql-contrib -y
echo ""
