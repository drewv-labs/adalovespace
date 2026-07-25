#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log app "=== Building PHD2 Engine"

maryguider="$ADA_CLUSTER/nodes/maryguider"

"$ADA_CLUSTER/core/debian/mods/install_phd2_deps.sh"
"$maryguider/phd2/compile.sh"
"$maryguider/phd2/configure.sh"
