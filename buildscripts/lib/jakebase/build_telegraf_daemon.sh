#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/install_telegraf.sh
${LIB}/jakebase/config_telegraf_daemon.sh
