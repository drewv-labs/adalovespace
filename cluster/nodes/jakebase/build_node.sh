#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

${ADA_CLUSTER}/core/build_core.sh

ada-log "main" "=== Building JakeBase Node"

jake="${ADA_CLUSTER}/nodes/jakebase"
${jake}/nfs/build_server.sh
${jake}/psql/build_server.sh
${jake}/mqtt/build_broker.sh
${jake}/ntfy/build_server.sh
${jake}/telegraf/build_engine.sh

${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh

ada-log "yay" "=== Build complete"
echo -n "Reboot? [y/n] " && read yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
