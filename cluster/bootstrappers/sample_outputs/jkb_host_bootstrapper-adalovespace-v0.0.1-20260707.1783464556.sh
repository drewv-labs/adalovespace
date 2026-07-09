#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "=== Git not found, installing..."
    sudo apt update -y && sudo apt install git -y
    echo "=== Git installed successfully"
fi

if [ ! -f /opt/adalovespace/cluster.env ]; then
    echo "Please 'sudo ln -s ~/adalovespace /opt' and try again!"
fi

sudo ln -s /opt/adalovespace/cluster/macros/ada-env.sh /usr/local/bin/ada-env
sudo chmod +755 /usr/local/bin/ada-env

sudo ln -s /opt/adalovespace/cluster/macros/ada-root.sh /usr/local/bin/ada-root
sudo chmod +755 /usr/local/bin/ada-root

sudo ln -s /opt/adalovespace/cluster/macros/safe-tee-sert.sh /usr/local/bin/safe-tee-sert
sudo chmod +755 /usr/local/bin/safe-tee-sert

sudo ln -s /opt/adalovespace/cluster/macros/sudo-check.sh /usr/local/bin/sudo-check
sudo chmod +755 /usr/local/bin/sudo-check
