#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster="${ADA_ROOT}/cluster"
core="${cluster}/core"

${core}/build_ubuntu_core.sh
${cluster}/nodes/jakebase/nfs/connect_client.sh "root"

${core}/debian/mods/build_debian_xfce_lightdm.sh
${core}/debian/mods/install_nomachine_deb.sh
${core}/ubuntu/mods/install_kstars_ekos.sh

${core}/debian/mods/apt_update_upgrade_slay.sh

sudo reboot
