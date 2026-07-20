#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

"${ADA_CLUSTER}/core/build_core.sh"

ada-log "main" "=== Building MaryGuider Node"

node="${ADA_CLUSTER}/nodes/maryguider"

"${node}/phd2/build_engine.sh"

"${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh"

ada-log "yay" "=== MaryGuider build complete and ready to reboot"
echo -n "Reboot? [y/n] " && read yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
