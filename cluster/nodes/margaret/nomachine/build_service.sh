#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_PLUM}=== Building NoMachine Service ==="

${ADA_CLUSTER}/core/ubuntu/modes/install_nomachine.sh
