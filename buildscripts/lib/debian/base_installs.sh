#!/bin/bash

BASEDIR=${HOME}/adalovespace/buildscripts

${BASEDIR}/lib/debian/install_uv_root.sh
${BASEDIR}/lib/debian/install_nfs_common.sh
${BASEDIR}/lib/debian/install_mosquitto_clients.sh
