#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building XFCE + LightDM GUI Stack"

"$ADA_CLUSTER/core/debian/mods/install_xfce_lightdm_stack.sh"
"$ADA_CLUSTER/nodes/margaret/marpro/xfce/configure.sh"
