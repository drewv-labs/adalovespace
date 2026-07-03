#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#
source /opt/adalovespace/cluster.conf

echo "=== Configuring Jakebase PostgreSQL Host Users"

sudo -u postgres psql << EOF
CREATE USER ${PSQL_FIELD_USER} WITH PASSWORD '${PSQL_FIELD_PASSWORD}';
CREATE USER ${PSQL_COURIER_USER} WITH PASSWORD '${PSQL_COURIER_PASSWORD}';
EOF

echo ""
