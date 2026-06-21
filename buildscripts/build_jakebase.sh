#!/bin/bash

export BASEDIR=~/adalovespace/buildscripts

${BASEDIR}/lib/debian/base_tune.sh
${BASEDIR}/lib/debian/base_installs.sh

${BASEDIR}/lib/debian/install_postgresql.sh
${BASEDIR}/lib/debian/install_nfs_host.sh
${BASEDIR}/lib/debian/install_mqtt_broker.sh

${BASEDIR}/lib/debian/apt_update_upgrade_slay.sh

sudo reboot
