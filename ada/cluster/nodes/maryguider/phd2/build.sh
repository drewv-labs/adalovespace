#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building PHD2 Engine"

maryguider="$ADA_CLUSTER/nodes/maryguider"

"$ADA_CLUSTER/core/debian/mods/install_phd2_deps.sh"
"$maryguider/phd2/compile.sh"
"$maryguider/phd2/configure.sh"
