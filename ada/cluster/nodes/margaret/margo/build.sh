#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building MarGo Stack (VNC)"

"$ADA_CLUSTER/core/debian/mods/install_vnc.sh"
"$ADA_CLUSTER/nodes/margaret/margo/configure.sh"
