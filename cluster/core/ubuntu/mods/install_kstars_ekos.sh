#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Installing Kstars and Ekos"
sudo apt-add-repository ppa:mutlaqja/ppa
sudo apt install indi-full kstars-bleeding -y
echo ""
