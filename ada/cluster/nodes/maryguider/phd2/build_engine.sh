#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "app" "=== Building PHD2 Engine"

node="${ADA_CLUSTER}/nodes/maryguider"

"${ADA_CLUSTER}/core/debian/mods/install_phd2_deps.sh"
"${node}/phd2/compile_engine.sh"
"${node}/phd2/config_engine.sh"
