#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster=${ADA_ROOT}/cluster

echo "${ADA_PLUM}=== Building Telegraf Ingestion Engine ==="

${cluster}/core/debian/mods/install_telegraf.sh
${cluster}/nodes/jakebase/telegraf/config_daemon.sh
