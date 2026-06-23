#!/bin/bash

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/install_postgresql.sh
${LIB}/jakebase/config_postgresql_host.sh
${LIB}/jakebase/create_postgresql_host_core.sh
