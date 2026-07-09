#!/bin/bash
set -euxo pipefall
source ada-preflight "${BASH_SOURCE[0]}"

core_dir="${ADA_ROOT}/cluster/core"
ada_dir="${core_dir}/ada"
ubu_dir="${core_dir}/ubuntu"

echo "${ADA_PLUM}=== Tuning Ubuntu Core"

${ada_dir}/prompt_ps1.sh
${ada_dir}/service_user.sh

${ubu_dir}/sys_tuner.sh
${ubu_dir}/base_installs.sh
