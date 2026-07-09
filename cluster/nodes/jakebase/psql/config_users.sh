#!/bin/bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

echo "=== Configuring Jakebase PostgreSQL Host Users"

sudo -u postgres psql << EOF
CREATE USER ${PSQL_CLUSTER_USER} WITH PASSWORD '${PSQL_CLUSTER_PASSWORD}';
CREATE USER ${PSQL_COURIER_USER} WITH PASSWORD '${PSQL_COURIER_PASSWORD}';
EOF

echo ""
