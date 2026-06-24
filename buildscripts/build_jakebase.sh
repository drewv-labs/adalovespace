#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/base_tune.sh
${LIB}/debian/base_installs.sh

${LIB}/jakebase/build_nfs_host.sh
${LIB}/jakebase/build_postgresql_host.sh
${LIB}/jakebase/build_mosquitto_broker.sh

${LIB}/debian/apt_update_upgrade_slay.sh

sudo reboot
