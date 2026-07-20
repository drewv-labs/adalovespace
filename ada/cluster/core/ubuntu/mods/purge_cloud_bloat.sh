#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Purging Cloud Bloat"

sudo touch /etc/cloud/cloud-init.disabled
sudo apt purge cloud-init -y
sudo rm -rf /etc/cloud/ /var/lib/cloud/

echo ""
