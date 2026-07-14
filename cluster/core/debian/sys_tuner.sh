#!/usr/bin/env bash
# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"
source arg-switches \
    "keep_bluetooth" \
    "keep_wifi" \
    "keep_modemmanager" \
    "keep_storage_spammer" \
    "keep_unattended_upgrades"

debmods="${ADA_CLUSTER}/core/debian/mods"

ada-log "sys" "=== Debian System Tuner"

# // Tunes
${debmods}/tune_sudoers.sh
${debmods}/tune_power_mode.sh

# // Optional Nukes
arg-switch-if "keep_bluetooth" "false" "${debmods}/nuke_bluetooth.sh"
arg-switch-if "keep_wifi" "false" "${debmods}/nuke_wifi.sh"
arg-switch-if "keep_modemmanager" "false" "${debmods}/nuke_modemmanager.sh"
arg-switch-if "keep_storage_spammer" "false" "${debmods}/nuke_storage_spammer.sh"
arg-switch-if "keep_unattended_upgrades" "false" "${debmods}/nuke_unattended_upgrades.sh"
