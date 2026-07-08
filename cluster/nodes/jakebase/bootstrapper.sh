#!/bin/bash
set -euxo pipefail
source sudo-check
source ada-env ${BASH_SOURCE[0]}

LIB=${HOME}/adalovespace/buildscripts/lib

${LIB}/debian/base_tune.sh
${LIB}/debian/base_installs.sh

${LIB}/jakebase/build_nfs_host.sh
${LIB}/jakebase/build_postgresql_host.sh
${LIB}/jakebase/build_mosquitto_broker.sh
${LIB}/jakebase/build_telegraf_daemon.sh

${LIB}/debian/apt_update_upgrade_slay.sh

sudo reboot
