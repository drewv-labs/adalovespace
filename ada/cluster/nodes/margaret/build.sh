#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building Margaret Node"

margaret="$ADA_CLUSTER/nodes/margaret"

"$margaret/xfce/build_gui.sh"
"$margaret/kstars/build_app.sh"
"$margaret/nomachine/build_service.sh"
