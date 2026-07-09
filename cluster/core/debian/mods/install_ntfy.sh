#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Installing Ntfy"
sudo apt install ntfy -y
echo ""
