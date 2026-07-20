#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"
source arg-switches \
    "keep_bluetooth" \
    "keep_wifi" \
    "keep_modemmanager" \
    "keep_storage_spammer" \
    "keep_unattended_upgrades" \
    "keep_rpi_connect"

core="${ADA_CLUSTER}/core"

ada-log "sys" "=== RaspberryPi System Tuner"

"${core}/debian/sys_tuner.sh" "$@"

arg-switch-if "keep_rpi_connect" "false" "${core}/rpi/mods/purge_rpi_connect.sh"
