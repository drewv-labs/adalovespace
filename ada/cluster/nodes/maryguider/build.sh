#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building MaryGuider Node"

maryguider="$ADA_CLUSTER/nodes/maryguider"

"$maryguider/phd2/build_engine.sh"
