#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluser_core=${ADA_ROOT}/cluster/core

${cluser_core}/debian/sys_tuner.sh
${cluser_core}/ubuntu/mods/nuke_cloud_bloat.sh
${cluser_core}/ubuntu/mods/nuke_snap.sh
