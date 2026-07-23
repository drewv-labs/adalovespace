#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building MarPro Stack (Ubuntu + XFCE + LightDM + NoMachine + KStars)"

marpro="$ADA_CLUSTER/nodes/margaret/marpro"

"$marpro/xfce/build.sh"
"$ADA_CLUSTER/core/ubuntu/mods/install_kstars.sh"
"$marpro/nomachine/build.sh"

ada-log yay "=== MarPro Build Complete"
