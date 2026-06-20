#!/bin/bash

export BASEDIR=${HOME}/adalovespace/buildscripts

${BASEDIR}/lib/debian/disable_unattended_upgrades.sh

${BASEDIR}/lib/debian/nuke_modemmanager.sh
${BASEDIR}/lib/debian/nuke_radios.sh
${BASEDIR}/lib/debian/nuke_storage_spammer.sh

${BASEDIR}/lib/debian/tune_power_mode.sh
