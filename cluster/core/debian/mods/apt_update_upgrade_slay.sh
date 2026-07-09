#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Updating, Upgrading, & Cleaning Up APT Packages"
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean -y
echo ""
