#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/jakebase/connect_nfs_client.sh
${LIB}/debian/install_mosquitto_clients.sh
