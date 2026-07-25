#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log app "=== Building XFCE + LightDM GUI Stack"

"$ADA_CLUSTER/core/debian/mods/install_xfce_lightdm_stack.sh"
"$ADA_CLUSTER/nodes/margaret/marpro/xfce/configure.sh"
