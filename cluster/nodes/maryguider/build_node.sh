#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

${ADA_CLUSTER}/core/build_core.sh

ada-log "main" "=== Building MaryGuider Node"

node="${ADA_CLUSTER}/nodes/maryguider"

${node}/phd2/build_engine.sh

${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh

ada-log "yay" "=== MaryGuider build complete and ready to reboot"
if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
