#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building Margaret Node"

margaret="$ADA_CLUSTER/nodes/margaret"

"$margaret/xfce/build.sh"
"$margaret/kstars/build.sh"
"$margaret/nomachine/build.sh"
