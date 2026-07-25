#!/usr/bin/env bash
set -euo pipefail

# Self-Bootstrap + build for JakeBase node.
# Run as root from a fresh checkout: sudo ./cluster/nodes/jakebase/build_node.sh

source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger main "=== Building JakeBase Node"

jakebase="$ADA_CLUSTER/nodes/jakebase"

"$jakebase/nfs/build.sh"
"$jakebase/psql/build.sh"
"$jakebase/mqtt/build.sh"
"$jakebase/ntfy/build.sh"
"$jakebase/telegraf/build.sh"
