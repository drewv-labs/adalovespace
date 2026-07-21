#!/usr/bin/env bash
set -euo pipefail

# // light weight working dir manager
DFLT_GITROOT="$HOME/adalovespace"
GITROOT="${ALT_GIT_ROOT:-$DFLT_GITROOT}"
if [ "$(pwd)" != "$GITROOT" ]; then
    _CURDIR="$(pwd)"
    cd "$GITROOT"
fi

# // CWD should be at user's adalovespace clone spot at this point
# // cluster.env vars are static so can source from the git repo
source ./ada/cluster.env

# // Using git-root code to bootstrap the node codespace, which will
# // serve as production runtime env
_tmp_lib="./$ADA_CLUST_S/lib"
source "$_tmp_lib/ada-strapper.sh" jakebase

# // With self-bootstrapper setting up our desired ADA_CODEBASE
# // switch to using the node codebase
sudo "$ADA_CLUSTER/core/build.sh" "$JAKEBASE_HW"

sudo "$ADA_CLUSTER/nodes/jakebase/build.sh"

sudo "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi
