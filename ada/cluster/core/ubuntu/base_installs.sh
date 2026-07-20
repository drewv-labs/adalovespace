#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log sys "=== Ubuntu Base Installs"

"$ADA_CLUSTER/core/debian/base_installs.sh"
