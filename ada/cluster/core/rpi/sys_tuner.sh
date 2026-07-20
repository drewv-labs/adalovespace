#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"
source arg-switches \
    keep_bluetooth \
    keep_wifi \
    keep_modemmanager \
    keep_storage_spammer \
    keep_unattended_upgrades \
    keep_rpi_connect

ada-log sys "=== RaspberryPi System Tuner"

"$ADA_CLUSTER/core/debian/sys_tuner.sh" "$@"

arg-switch-if keep_rpi_connect false "$ADA_CLUSTER/core/rpi/mods/purge_rpi_connect.sh"
