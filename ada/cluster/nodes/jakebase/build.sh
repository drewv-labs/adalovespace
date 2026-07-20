#!/usr/bin/env bash
# Self-Bootstrap + build for JakeBase node.
# Run as root from a fresh checkout: sudo ./cluster/nodes/jakebase/build_node.sh
set -euo pipefail

source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building JakeBase Node"

jakebase="$ADA_CLUSTER/nodes/jakebase"

"$jakebase/nfs/build.sh"
"$jakebase/psql/build.sh"
"$jakebase/mqtt/build.sh"
"$jakebase/ntfy/build.sh"
"$jakebase/telegraf/build.sh"
