#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building MarPro Stack (XFCE + LightDM + NoMachine)"

margaret="$ADA_CLUSTER/nodes/margaret/marpro"

"$margaret/xfce/build.sh"
"$margaret/nomachine/build.sh"

ada-log yay "=== MarPro Build Complete"
