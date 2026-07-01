#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if ! command -v uv &> /dev/null; then
    echo "!!! uv is not installed. Installing now..."
    /opt/ada-codespace/nodes/_core/debian/install_uv_root.sh
fi
