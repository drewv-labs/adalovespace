#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

${ADA_ROOT}/cluster/core/debian/mods/install_uv_root.sh
