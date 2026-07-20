#!/usr/bin/env bash
# Self-Bootstrap + build for JakeBase node.
# Run as root from a fresh checkout: sudo ./cluster/nodes/jakebase/build_node.sh
set -euo pipefail

source ada-preflight "$BASH_SOURCE[0]"

ada-log "main" "=== Building JakeBase Node"

jake="${ADA_CLUSTER}/nodes/jakebase"

"${jake}/nfs/build.sh"
"${jake}/psql/build.sh"
"${jake}/mqtt/build.sh"
"${jake}/ntfy/build.sh"
"${jake}/telegraf/build.sh"

"${ADA_CLUSTER}/core/apt_update_upgrade_slay.sh"

ada-log "yay" "=== JakeBase Node Build Complete!"
echo -n "Reboot? [y/n] " && read yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
