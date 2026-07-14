#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

${ADA_CLUSTER}/core/build_core.sh

ada-log "main" "=== Building Caroline-V Node"

node="${ADA_CLUSTER}/nodes/caroline"

${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh

ada-log "yay" "=== Build complete"
if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
