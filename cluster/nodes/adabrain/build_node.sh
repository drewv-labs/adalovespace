#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

${ADA_CLUSTER}/core/build_core.sh "debian"

echo "${ADA_PLUM}=== Building AdaBrain Node"

brain="${ADA_CLUSTER}/nodes/adabrain"
${brain}/indi/build_server.sh

${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh

echo "${YAY_GRN}=== Build complete"
if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    echo "${ADA_PLUM}=== Rebooting"
    sudo reboot
fi
