#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log main "=== Building AdaBrain Node"

adabrain="$ADA_CLUSTER/nodes/adabrain"

"$adabrain/indi/build.sh"
