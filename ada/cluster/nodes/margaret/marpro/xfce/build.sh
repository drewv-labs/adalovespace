#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building XFCE + LightDM GUI ==="

"$ADA_CLUSTER/core/debian/mods/install_xfce_lightdm_stack.sh"
SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
"$SCRIPT_DIR/configure.sh"
