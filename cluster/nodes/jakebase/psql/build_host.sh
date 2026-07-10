#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster=${ADA_ROOT}/cluster
jakepsql=${cluster}/nodes/jakebase/psql

echo "${ADA_PLUM}=== Building JakegreSQL PostgreSQL Database ==="
${cluster}/core/debian/mods/install_postgresql.sh

${jakepsql}/config_host_settings.sh
${jakepsql}/config_database.sh
${jakepsql}/config_users.sh
${jakepsql}/config_tables.sh
