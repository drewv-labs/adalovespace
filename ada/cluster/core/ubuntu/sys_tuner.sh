#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"
source arg-switches \
    "keep_bluetooth" \
    "keep_wifi" \
    "keep_modemmanager" \
    "keep_storage_spammer" \
    "keep_unattended_upgrades" \
    "keep_cloud_bloat" \
    "keep_snap"

core="${ADA_CLUSTER}/core"

ada-log "sys" "=== Ubuntu System Tuner"

arg-switch-if "keep_cloud_bloat" "false" "${core}/ubuntu/mods/purge_cloud_bloat.sh"
arg-switch-if "keep_snap" "false" "${core}/ubuntu/mods/purge_snap.sh"

"${core}/debian/sys_tuner.sh" "$@"
