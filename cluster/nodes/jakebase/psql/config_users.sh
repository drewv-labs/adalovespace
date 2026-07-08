#!/bin/bash
set -euxo pipefail
source sudo-check
source ada-env ${BASH_SOURCE[0]}

echo "=== Configuring Jakebase PostgreSQL Host Users"

sudo -u postgres psql << EOF
CREATE USER ${PSQL_FIELD_USER} WITH PASSWORD '${PSQL_FIELD_PASSWORD}';
CREATE USER ${PSQL_COURIER_USER} WITH PASSWORD '${PSQL_COURIER_PASSWORD}';
EOF

echo ""
