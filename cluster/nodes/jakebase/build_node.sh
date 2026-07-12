#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster="${ADA_ROOT}/cluster"
jake="${cluster}/nodes/jakebase"

${cluster}/core/build_core.sh "debian"

echo "${ADA_PLUM}=== Building JakeBase Node"

${jake}/nfs/build_host.sh
${jake}/psql/build_host.sh
${jake}/mqtt/build_broker.sh
${jake}/telegraf/build_daemon.sh
${jake}/ntfy/build_server.sh

${cluster}/core/apt_update_upgrade_slay.sh

echo "${YAY_GRN}=== Build complete"

if [[ "$(read -rp 'Reboot? [y/n] ' yn; echo "$yn")" =~ ^[Yy]$ ]]; then
    echo "${ADA_PLUM}=== Rebooting"
    sudo reboot
fi
