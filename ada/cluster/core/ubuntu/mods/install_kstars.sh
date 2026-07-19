#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Installing Kstars and Ekos"

sudo apt-add-repository ppa:mutlaqja/ppa
sudo apt update -y && sudo apt install kstars-bleeding -y

echo ""
