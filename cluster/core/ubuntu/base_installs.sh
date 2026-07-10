#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

if ! command -v uv &> /dev/null; then
    echo "${ERR_RED}!!! uv is not installed. Installing now..."
    ${ADA_ROOT}/cluster/core/debian/mods/install_uv_root.sh
fi
