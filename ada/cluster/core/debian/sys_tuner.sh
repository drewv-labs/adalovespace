#!/usr/bin/env bash
# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

source arg-switches \
    keep_bluetooth \
    keep_wifi \
    keep_modemmanager \
    keep_storage_spammer \
    keep_unattended_upgrades


ada-log sys "=== Debian System Tuner"

# // Tunes
debmods="$ADA_CLUSTER/core/debian/mods"

"$debmods/tune_sudoers.sh"
"$debmods/tune_power_mode.sh"

# // Optional Purges
arg-switch-if keep_bluetooth false "$debmods/purge_bluetooth.sh"
arg-switch-if keep_wifi false "$debmods/purge_wifi.sh"
arg-switch-if keep_modemmanager false "$debmods/purge_modemmanager.sh"
arg-switch-if keep_storage_spammer false "$debmods/purge_storage_spammer.sh"
arg-switch-if keep_unattended_upgrades false "$debmods/purge_unattended_upgrades.sh"
