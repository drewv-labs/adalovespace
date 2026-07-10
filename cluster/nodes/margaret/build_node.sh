#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster="${ADA_ROOT}/cluster"
marg="${cluster}/nodes/margaret"

${cluster}/core/build_core.sh "ubuntu"

echo "${ADA_PLUM}=== Building Margaret Node"

${marg}/xfce/build_gui.sh
${marg}/kstars/build_app.sh
${marg}/nomachine/build_app.sh

${cluster}/core/apt_update_upgrade_slay.sh

echo "${YAY_GRN}=== Build complete"

if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    echo "${ADA_PLUM}=== Rebooting"
    sudo reboot
fi
