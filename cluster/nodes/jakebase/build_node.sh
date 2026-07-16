#!/usr/bin/env bash
# Self-Bootstrap + build for JakeBase node.
# Run as root from a fresh checkout: sudo ./cluster/nodes/jakebase/build_node.sh
set -euo pipefail

# -- Embedded bootstrap: resolve repo root, set up symlinks --
_selfboot_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
source "${_selfboot_dir}/lib/ada-selfboot.sh" jakebase
echo "checkpoint1"
source ada-preflight "${BASH_SOURCE[0]}"
echo "checkpoint2"
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
