#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/install_mosquitto_broker.sh
${LIB}/jakebase/config_mosquitto_broker.sh
