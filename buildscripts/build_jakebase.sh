#!/bin/bash

export BASEDIR=~/adalovespace/buildscripts

${BASEDIR}/lib/debian/base_tune.sh
${BASEDIR}/lib/debian/base_installs.sh

${BASEDIR}/lib/jakebase/build_nfs_host.sh
${BASEDIR}/lib/jakebase/build_postgresql_host.sh
${BASEDIR}/lib/jakebase/build_mosquitto_broker.sh

${BASEDIR}/lib/debian/apt_update_upgrade_slay.sh

sudo reboot
