#!/usr/bin/env bash
set -euo pipefail

# // light weight working dir manager
DFLT_GITROOT="$HOME/adalovespace"
GITROOT="${ALT_GIT_ROOT:-$DFLT_GITROOT}"
if [ "$(pwd)" != "$GITROOT" ]; then
    _CURDIR="$(pwd)"
    cd "$GITROOT"
fi

# // Do the thing
echo "... Attempting to Load Env Vars from ada/cluster.env..."
source ada/cluster.env
echo "... Attempting JakeBase Node Bootstrapper ($ADA_CLUST_S/lib/ada-strapper.sh)..."
source "$ADA_CLUST_S/lib/ada-strapper.sh" "margaret"

ada-log main "=== JakeBase Node Bootstrapper Complete"
ada-log main "=== JakeBase Node Build Start"

# // With self-bootstrapper setting up our desired ADA_CODEBASE
# // switch to using the node codebase
sudo "$ADA_CLUSTER/core/build.sh" "$MARGARET_HW"
sudo "$ADA_CLUSTER/nodes/margaret/build.sh"
sudo "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi

ada-log "yay" "=== JakeBase Node Build Complete"
echo -n "Reboot? [y/n] " && read yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
