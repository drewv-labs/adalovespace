#!/bin/bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

echo "${ADA_BLU1}=== Configuring JakeBase PostgreSQL Host Database; ${PSQL_DB_NAME}"

sudo psql -U postgres << EOF
CREATE DATABASE ${PSQL_DB_NAME};"
EOF

echo ""
