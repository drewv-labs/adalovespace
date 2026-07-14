#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

${ADA_CLUSTER}/core/build_core.sh ubuntu

ada-log "main" "=== Building Margaret Node"

node="${ADA_CLUSTER}/nodes/margaret"

${node}/xfce/build_gui.sh
${node}/kstars/build_app.sh
${node}/nomachine/build_service.sh

${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh

ada-log "yay" "=== Margaret build complete and ready to reboot"
if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
