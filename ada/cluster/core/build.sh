#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

core="${ADA_ROOT}/cluster/core"

variant="${1:-debian}"
shift 2>/dev/null || true

available_variants=$(ls -d ${core}/* | xargs -n 1 basename | grep -v '^ada$' | tr '\n' ' ')
if [[ ! " $available_variants " =~ " $variant " ]]; then
    ada-log "oof" "=== Invalid variant: $variant. Available variants are: $available_variants"
    exit 1
fi

export ADA_BUILD_VARIANT="$variant"

ada-log "main" "=== Building $variant Core"

"${core}/prompt_ps1.sh"
"${core}/service_user.sh"

"${core}/${variant}/sys_tuner.sh" "$@"
"${core}/${variant}/base_installs.sh"

ada-log "yay" "=== $variant Core Build Complete!"
