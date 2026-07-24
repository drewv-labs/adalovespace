#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building KStars Application"

"$ADA_CLUSTER/core/ubuntu/mods/install_kstars.sh"
