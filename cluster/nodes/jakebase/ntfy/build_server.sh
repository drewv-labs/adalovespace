#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

cluster=${ADA_ROOT}/cluster

echo "${ADA_PLUM}=== Building Ntfy Server ==="

${cluster}/core/debian/mods/install_ntfy.sh
# ${cluster}/nodes/jakebase/ntfy/config_server.sh
