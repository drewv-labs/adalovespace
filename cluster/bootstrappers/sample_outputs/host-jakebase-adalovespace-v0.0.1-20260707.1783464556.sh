#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use 'sudo' to execute this script." >&2
    exit 1
fi

# 1. Clone the git repository directly to /opt/adalovespace
if ! command -v git &> /dev/null; then
    echo "=== Git not found, installing..."
    sudo apt update -y && sudo apt install git -y
    echo "=== Git installed successfully"
fi

sudo mkdir -p /opt/adalovespace
sudo git clone https://github.com/dvandagriff/adalovespace.git /opt/adalovespace

# 2. Set specific permissions if needed (example: make build scripts executable)
sudo chmod +x /opt/adalovespace/cluster/nodes/jakebase/build_node.sh

# 3. Create symlinks for cluster macros
sudo ln -s /opt/adalovespace/cluster/lib/ada-preflight.sh /usr/local/bin/ada-preflight
sudo ln -s /opt/adalovespace/cluster/lib/ada-preflight-nosudo.sh /usr/local/bin/ada-preflight-nosudo
sudo ln -s /opt/adalovespace/cluster/lib/safe-tee-sed.sh /usr/local/bin/safe-tee-sed

# 4. Run build script if it exists
buildscript="/opt/adalovespace/cluster/nodes/jakebase/build_node.sh"
if [ -f "$buildscript" ]; then
    echo "Executing build script: ${buildscript}"
    exec "${buildscript}"
else
    echo "Build script not found at $buildscript. Aborting."
    exit 1
fi
