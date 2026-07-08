#!/bin/bash
set -euxo pipefail
source sudo-check
source ada-env ${BASH_SOURCE[0]}

NODES=/opt/adalovespace/buildscripts/lib

${NODES}/_core/debian/install_telegraf.sh
${NODES}/jakebase/telegraf/config_daemon.sh
