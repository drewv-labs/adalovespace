#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/install_nfs_common.sh
${LIB}/jakebase/connect_nfs_client.sh
${LIB}/debian/install_mosquitto_clients.sh
