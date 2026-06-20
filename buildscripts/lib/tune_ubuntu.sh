#!/bin/bash

export BASEDIR=${HOME}/adalovespace/buildscripts

${BASEDIR}/lib/debian/base_tune.sh
${BASEDIR}/lib/ubuntu/base_tune.sh
${BASEDIR}/lib/debian/apt_update_upgrade_slay.sh
