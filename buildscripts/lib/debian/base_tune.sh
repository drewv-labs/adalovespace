#!/bin/bash

DEB=${HOME}/adalovespace/buildscripts/lib/debian

${DEB}/disable_unattended_upgrades.sh
${DEB}/nuke_modemmanager.sh
${DEB}/nuke_radios.sh
${DEB}/nuke_storage_spammer.sh
${DEB}/tune_power_mode.sh
