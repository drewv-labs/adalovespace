#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#
source ${HOME}/adalovespace/cluster.conf

echo "=== Configuring Jakebase PostgreSQL Host Users"

sudo -u postgres psql << 'EOF'

-- # Generated automatically by JakeBase build script
-- # Configuration Date: $(date '+%Y-%m-%d %H:%M:%S')
CREATE USER coffee_courier WITH PASSWORD 'coffeecourier';
CREATE USER field_agent WITH PASSWORD 'fieldagent';
EOF

echo ""
