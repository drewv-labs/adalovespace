#!/bin/bash
set -euxo pipefail
source sudo-check

echo "=== Installing Kstars and Ekos"
sudo apt-add-repository ppa:mutlaqja/ppa
sudo apt install indi-full kstars-bleeding -y
echo ""
