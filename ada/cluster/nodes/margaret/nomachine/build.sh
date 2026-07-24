#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building NoMachine Service"

"$ADA_CLUSTER/core/debian/mods/install_nomachine.sh"
