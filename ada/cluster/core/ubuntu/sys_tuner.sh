#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

source arg-switches \
    keep_bluetooth \
    keep_wifi \
    keep_modemmanager \
    keep_storage_spammer \
    keep_unattended_upgrades \
    keep_cloud_bloat \
    keep_snap

ada-log sys "=== Ubuntu System Tuner"

arg-switch-if keep_cloud_bloat false "$ADA_CLUSTER/core/ubuntu/mods/purge_cloud_bloat.sh"
arg-switch-if keep_snap false "$ADA_CLUSTER/core/ubuntu/mods/purge_snap.sh"

"$ADA_CLUSTER/core/debian/sys_tuner.sh" "$@"
