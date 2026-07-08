#!/bin/bash
set -euxo pipefail
source sudo-check

cluser_core=/opt/adalovespace/cluster/core
deb=${cluser_core}/debian
ubu=${cluser_core}/ubuntu

${deb}/sys_tuner.sh
${ubu}/mods/nuke_cloud_bloat.sh
${ubu}/mods/nuke_snap.sh
