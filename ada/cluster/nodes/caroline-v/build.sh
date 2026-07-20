#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building Caroline-V Node"

carolinev="$ADA_CLUSTER/nodes/caroline-v"
# ToDo...
