#!/bin/bash

echo "=== Purging Storage Spammer"

sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
echo ""
