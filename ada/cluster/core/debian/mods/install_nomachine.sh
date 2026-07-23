#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

v_majmin="${NM_V_MAJOR}.${NM_V_MINOR}"
v_full="${NM_V_MAJOR}.${NM_V_MINOR}.${NM_V_PATCH}_${NM_V_BUILD}"

ada-log mod "=== Installing NoMachine"

wget https://download.nomachine.com/download/${v_majmin}/Linux/nomachine_${v_full}_amd64.deb
sudo dpkg -i nomachine_${v_full}_amd64.deb
