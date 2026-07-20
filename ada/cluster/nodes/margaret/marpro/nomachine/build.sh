#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log app "=== Building NoMachine Service ==="

"$ADA_CLUSTER/core/ubuntu/mods/install_nomachine.sh"
