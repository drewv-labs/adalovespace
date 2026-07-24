#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building VNC Service"

"$ADA_CLUSTER/core/debian/mods/install_vnc.sh"
