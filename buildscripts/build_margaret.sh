#!/bin/bash

export BASEDIR=~/adalovespace/buildscripts

${BASEDIR}/lib/debian/base_tune.sh
${BASEDIR}/lib/debian/base_install.sh

${BASEDIR}/lib/connect_jake_debian.sh

${BASEDIR}/lib/debian/build_debian_xfce_lightdm.sh
${BASEDIR}/lib/debian/install_nomachine_deb.sh
${BASEDIR}/lib/ubuntu/install_kstars_ekos.sh

${BASEDIR}/lib/debian/apt_update_upgrade_purge.sh

sudo reboot
