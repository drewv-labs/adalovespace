#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

source ${HOME}/adalovespace/cluster_config.sh

echo "=== Configuring JakeBase PostgreSQL Host Database; ${PSQL_DB_NAME}"
sudo psql -U postgres -c "CREATE DATABASE ${PSQL_DB_NAME};"
echo ""
