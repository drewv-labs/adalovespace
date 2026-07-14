#!/usr/bin/env bash
# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"
source arg-switches "keep_radios" "keep_bluetooth" "keep_wifi"

debmods="${ADA_CLUSTER}/core/debian/mods"

ada-log "sys" "=== Debian System Tuner"

if [ $keep_radios = true ]; then
    ada-log "debug" "---> Keeping Bluetooth & Wi-Fi Radios"
else
    if [ $keep_bluetooth = false ]; then
        ${debmods}/nuke_bluetooth.sh
    fi
    if [ $keep_wifi = false ]; then
        ${debmods}/nuke_wifi.sh
    fi
fi

${debmods}/nuke_modemmanager.sh
${debmods}/nuke_storage_spammer.sh
${debmods}/nuke_unattended_upgrades.sh
${debmods}/tune_power_mode.sh
${debmods}/tune_sudoers.sh
