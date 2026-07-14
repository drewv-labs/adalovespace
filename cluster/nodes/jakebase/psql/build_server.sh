#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "app" "=== Building JakegreSQL PostgreSQL Database ==="

${ADA_CLUSTER}/core/debian/mods/install_postgresql.sh
${ADA_CLUSTER}/nodes/jakebase/psql/config_server.sh
