#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log app "=== Building JakegreSQL PostgreSQL Database ==="

"$ADA_CLUSTER/core/debian/mods/install_postgresql.sh"
"$ADA_CLUSTER/nodes/jakebase/psql/configure.sh"
