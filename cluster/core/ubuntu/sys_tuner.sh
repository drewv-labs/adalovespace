#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluser_core=${ADA_ROOT}/cluster/core
deb=${cluser_core}/debian
ubu=${cluser_core}/ubuntu

${deb}/sys_tuner.sh
${ubu}/mods/nuke_cloud_bloat.sh
${ubu}/mods/nuke_snap.sh
