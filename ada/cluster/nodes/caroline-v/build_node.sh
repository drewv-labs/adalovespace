#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

"${ADA_CLUSTER}/core/build_core.sh"

ada-log "main" "=== Building Caroline-V Node"

node="${ADA_CLUSTER}/nodes/caroline-v"

"${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh"

ada-log "yay" "=== Build complete"
echo -n "Reboot? [y/n] " && read yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
