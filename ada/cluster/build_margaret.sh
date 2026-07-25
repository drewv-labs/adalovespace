#!/usr/bin/env bash
set -euo pipefail

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUST_S/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

# // light weight working dir manager
DFLT_GITROOT="$HOME/adalovespace"
GITROOT="${ALT_GIT_ROOT:-$DFLT_GITROOT}"
if [ "$(pwd)" != "$GITROOT" ]; then
    _CURDIR="$(pwd)"
    cd "$GITROOT"
fi

# // Do the thing — load env and bootstrap first
source ada/cluster.env
source "$ADA_CLUST_S/lib/ada-strapper.sh" margaret

ada-logger main "=== Margaret Node Build Start"

# // With self-bootstrapper setting up our desired ADA_CODEBASE
# // switch to using the node codebase
sudo "$ADA_CLUSTER/core/build.sh" "$MARGARET_HW"

# // Accept variant args and forward to margaret/build.sh
if [ $# -gt 0 ]; then
    sudo "$ADA_CLUSTER/nodes/margaret/build.sh" "$@"
else
    sudo "$ADA_CLUSTER/nodes/margaret/build.sh"
fi

# // Full system cleanup as final step before reboot
sudo "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi

ada-logger yay "=== Margaret Node Build Complete"
if [[ -t 0 ]]; then
    echo -n "Reboot? [y/N] " && read -r -t 30 yn
    if [[ "${yn,,}" == y ]]; then
        sudo reboot
    fi
else
    ada-logger main "Non-interactive mode: skipping reboot"
fi
