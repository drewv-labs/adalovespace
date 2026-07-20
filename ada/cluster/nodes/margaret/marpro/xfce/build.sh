#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building XFCE + LightDM GUI ==="

"$ADA_CLUSTER/core/debian/mods/install_xfce_lightdm_stack.sh"
"$ADA_CLUSTER/nodes/margaret/xfce/config_passwordless_login.sh"
