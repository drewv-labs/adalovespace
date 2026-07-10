#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU2}=== Ubuntu Base Installs"

${ADA_ROOT}/cluster/core/debian/base_installs.sh
