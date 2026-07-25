#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log main "=== Building MaryGuider Node"

maryguider="$ADA_CLUSTER/nodes/maryguider"

"$maryguider/phd2/build.sh"
