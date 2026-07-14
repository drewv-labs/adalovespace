#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Installing Gopass Keychain"

sudo apt install -y gopass
mkdir -p ~/.local/share/gopass/stores/root
git clone git@your-git-server:cluster-secrets.git \
  ~/.local/share/gopass/stores/root --depth=1
gpgconf --kill gpg-agent

echo ""
