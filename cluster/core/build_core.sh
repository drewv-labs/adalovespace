#!/bin/bash
set -euxo pipefall
source ada-preflight "${BASH_SOURCE[0]}"

core="${ADA_ROOT}/cluster/core"

if [ -z "$1" ]; then
    variant="debian"
else
    variant="$1"
fi

available_variants=$(ls -d ${core}/*/ | xargs -n 1 basename | grep -v '^ada$')
if [[ ! " ${available_variants[@]} " =~ " ${variant} " ]]; then
    echo "${ADA_RED}=== Invalid variant: ${variant}. Available variants are: ${available_variants[*]}"
    exit 1
fi

echo "${ADA_PLUM}=== Building ${variant} Core"

${core}/ada/prompt_ps1.sh
${core}/ada/service_user.sh

${core}/${variant}/sys_tuner.sh
${core}/${variant}/base_installs.sh
