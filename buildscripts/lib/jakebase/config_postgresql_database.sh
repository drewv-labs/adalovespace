#!/bin/bash

source ${HOME}/adalovespace/cluster_config.sh

echo "=== Configuring JakeBase PostgreSQL Host Database; ${PSQL_DB_NAME}"
sudo psql -U postgres -c "CREATE DATABASE ${PSQL_DB_NAME};"
echo ""
