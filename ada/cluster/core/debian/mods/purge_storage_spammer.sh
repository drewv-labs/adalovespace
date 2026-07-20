#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Purging Multipathd Storage Spammer"

sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
