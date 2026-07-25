#!/usr/bin/env bash

set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

variant="${1:-debian}"
shift 2>/dev/null || true

available_variants=$(ls -d "$ADA_CLUSTER/core/*" | xargs -n 1 basename | grep -v '^ada$' | tr '\n' ' ')
if [[ ! " $available_variants " =~ " $variant " ]]; then
    ada-logger "oof" "=== Invalid variant: $variant. Available variants are: $available_variants"
    exit 1
fi

ada-logger main "=== Building $variant Core"

"$ADA_CLUSTER/core/prompt_ps1.sh"
"$ADA_CLUSTER/core/service_user.sh"

"$ADA_CLUSTER/core/$variant/sys_tuner.sh" "$@"
"$ADA_CLUSTER/core/$variant/base_installs.sh"
