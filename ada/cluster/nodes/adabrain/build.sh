#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building AdaBrain Node"

adabrain="$ADA_CLUSTER/nodes/adabrain"

"$adabrain/indi/build.sh"
