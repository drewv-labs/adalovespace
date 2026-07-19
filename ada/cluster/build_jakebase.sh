#!/usr/bin/env bash
set -euo pipefail

# // light weight working dir manager
GITROOT="${ALT_GIT_ROOT:-$HOME}"
if [ "$(pwd)" != "$GITROOT" ]; then
    _CURDIR="$(pwd)"
    cd "$GITROOT"
fi

# // Do the thing
source ./ada/cluster.env
source "./${ADA_CLUST_S}/lib/ada-selfboot.sh" "jakebase"

# // With self-bootstrapper setting up our desired ADA_CODEBASE
# // switch to using the node codebase
#
sudo "${ADA_CLUSTER}/core/build_core.sh" "$JAKEBASE_HW"
sudo "${ADA_CLUSTER}/nodes/jakebase/build_node.sh"
sudo "${ADA_CLUSTER}/core/apt_update_upgrade_purge.sh"

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi
