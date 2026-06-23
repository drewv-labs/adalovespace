#!/bin/bash

export BASEDIR=${HOME}/adalovespace/buildscripts

${BASEDIR}/lib/jakebase/connect_nfs_client.sh
${BASEDIR}/lib/debian/install_mosquitto_clients.sh
