#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building Telegraf Ingestion Engine ==="

"$ADA_CLUSTER/core/debian/mods/install_telegraf.sh"
"$ADA_CLUSTER/nodes/jakebase/telegraf/configure.sh"
