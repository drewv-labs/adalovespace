#!/bin/bash

export BASEDIR=~/adalovespace/ada/builds

${BASEDIR}/lib/base_debian_tune.sh
${BASEDIR}/lib/base_debian_install.sh

${BASEDIR}/lib/debian/install_postgresql.sh
${BASEDIR}/lib/debian/install_nfs_host.sh
${BASEDIR}/lib/debian/install_mqtt_broker.sh

${BASEDIR}/lib/debian/apt_update_upgrade_slay.sh

sudo reboot
