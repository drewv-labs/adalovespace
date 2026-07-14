#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

core=${ADA_CLUSTER}/core

ada-log "sys" "=== Ubuntu System Tuner"

${core}/debian/sys_tuner.sh $@

${core}/ubuntu/mods/nuke_cloud_bloat.sh
${core}/ubuntu/mods/nuke_snap.sh
