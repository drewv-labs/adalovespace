#!/usr/bin/env bash
set -euo pipefail

# // light weight working dir manager
DFLT_GITROOT="$HOME/adalovespace"
GITROOT="${ALT_GIT_ROOT:-$DFLT_GITROOT}"
if [ "$(pwd)" != "$GITROOT" ]; then
    _CURDIR="$(pwd)"
    cd "$GITROOT"
fi

# // Default build variant (marpro or margo)
BUILD_VARIANT="${1:-marpro}"
case "$BUILD_VARIANT" in
    marpro|margo|legacy)
        ;;
    *)
        echo "ERROR: Unknown build variant '$BUILD_VARIANT'. Use: marpro | margo | legacy"
        exit 1
        ;;
esac

# // Do the thing
echo "... Attempting to Load Env Vars from ada/cluster.env..."
source ada/cluster.env
echo "... Attempting Margaret Node Bootstrapper ($ADA_CLUST_S/lib/ada-strapper.sh)..."
source "$ADA_CLUST_S/lib/ada-strapper.sh" "margaret"

ada-log main "=== Margaret Node Build Start (variant=$BUILD_VARIANT)"

# // With self-bootstrapper setting up our desired ADA_CODEBASE
# // switch to using the node codebase
sudo "$ADA_CLUSTER/core/build.sh" "$MARGARET_HW"
sudo "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"

case "$BUILD_VARIANT" in
    marpro)
        sudo "$ADA_CLUSTER/nodes/margaret/marpro/build.sh"
        ;;
    margo)
        sudo "$ADA_CLUSTER/nodes/margaret/margo/build.sh"
        sudo "$ADA_CLUSTER/nodes/margaret/margo/configure.sh"
        ;;
    legacy)
        sudo "$ADA_CLUSTER/nodes/margaret/build.sh"
        ;;
esac

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi

ada-log "yay" "=== Margaret Node Build Complete ($BUILD_VARIANT)"
echo -n "Reboot? [y/n] " && read yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    ada-log "main" "=== Rebooting"
    sudo reboot
fi
