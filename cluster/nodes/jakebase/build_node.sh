#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster=${ADA_ROOT}/cluster
jbase=${cluster}/nodes/jakebase

${cluster}/core/build_debian_core.sh

echo "${ADA_PLUM}=== Building JakeBase Node"
${jbase}/nfs/build_host.sh
${jbase}/psql/build_host.sh
${jbase}/mqtt/build_broker.sh
${jbase}/telegraf/build_daemon.sh
${jbase}/ntfy/build_server.sh

${cluster}/core/apt_update_upgrade_slay.sh

echo "${YAY_GRN}=== Build complete"
if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    echo "${ADA_PLUM}=== Rebooting"
    sudo reboot
fi
