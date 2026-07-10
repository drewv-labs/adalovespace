#!/bin/bash
set -euxo pipefall
source ada-preflight "${BASH_SOURCE[0]}"

core_dir="${ADA_ROOT}/cluster/core"
ada_dir="${core_dir}/ada"
deb_dir="${core_dir}/debian"

echo "${ADA_PLUM}=== Tuning Debian Core"

${ada_dir}/prompt_ps1.sh
${ada_dir}/service_user.sh

${deb_dir}/sys_tuner.sh
${deb_dir}/base_installs.sh
