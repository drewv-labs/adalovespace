#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger main "=== Building MarPro Stack (XFCE + LightDM + NoMachine)"

margaret="$ADA_CLUSTER/nodes/margaret"

"$margaret/xfce/build.sh"
"$margaret/nomachine/build.sh"

ada-logger yay "=== MarPro Build Complete"
