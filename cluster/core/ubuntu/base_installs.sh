#!/bin/bash
set -euxo pipefail
source sudo-check

if ! command -v uv &> /dev/null; then
    echo "!!! uv is not installed. Installing now..."
    /opt/adalovespace/cluster/core/debian/mods/install_uv_root.sh
fi
