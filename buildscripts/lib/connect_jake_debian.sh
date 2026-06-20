#!/bin/bash

export BASEDIR=${HOME}/adalovespace/buildscripts

${BASEDIR}/lib/debian/connect_jake_mqtt.sh
${BASEDIR}/lib/debian/connect_jake_nfs.sh
