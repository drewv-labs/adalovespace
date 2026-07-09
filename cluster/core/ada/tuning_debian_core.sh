#!/bin/bash
set -euxo pipefall
source ada-sudo-check
if ! check_sudo_access; then
    echo "Aborting deployment"
    exit 1
fi
source ada-env "${BASH_SOURCE[0]}"
source ada-root

root_dir="$(find_ada_root ${BASH_SOURCE[0]})"
core_dir="${root_dir}/cluster/core"
ada_dir="${core_dir}/ada"
deb_dir="${core_dir}/debian"

echo "${ADA_PLUM}=== Tuning Debian Core"

${ada_dir}/prompt_ps1.sh
${ada_dir}/service_user.sh

${deb_dir}/sys_tuner.sh
${deb_dir}/base_installs.sh
