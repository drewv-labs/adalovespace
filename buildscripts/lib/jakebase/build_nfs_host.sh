#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/install_nfs_kernel_server.sh
${LIB}/jakebase/config_nfs_host.sh
