#!/bin/bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

cluster=${ADA_ROOT}/cluster

${cluster}/core/debian/mods/install_telegraf.sh
${cluster}/nodes/jakebase/telegraf/config_daemon.sh
