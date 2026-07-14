#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "app" "=== Building KStars App ==="

${ADA_CLUSTER}/core/ubuntu/modes/install_kstars.sh
