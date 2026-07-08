#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

A_NODES=/opt/ada-codespace/nodes
JAKE=${A_NODES}/jakebase

${A_NODES}/_core/debian/install_postgresql.sh

${JAKE}/psql/config_host_settings.sh
${JAKE}/psql/config_database.sh
${JAKE}/psql/config_users.sh
${JAKE}/psql/config_tables.sh
