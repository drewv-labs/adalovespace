#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Purging Storage Spammer"
sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
echo ""
