#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_PLUM}=== Building KStars App ==="

${ADA_CLUSTER}/core/ubuntu/modes/install_kstars.sh
