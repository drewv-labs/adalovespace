#!/bin/bash
set -euxo pipefail
source sudo-check

echo "=== Purging Storage Spammer"
sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
echo ""
