#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing Gopass Keychain"

sudo apt install -y gopass
mkdir -p ~/.local/share/gopass/stores/root
git clone git@your-git-server:cluster-secrets.git \
  ~/.local/share/gopass/stores/root --depth=1
gpgconf --kill gpg-agent

echo ""
