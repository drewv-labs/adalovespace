#!/usr/bin/env bash
# ================================================================
# Name: build_carolinev.sh
# Version: 1.0.0
# Description: Bootstrapper for setting up Caroline-V node
# Author: Drew Vandagriff
# ==============================================================

set -euo pipefail

# Trap for error handling
trap 'echo "ERROR: Script failed at line $LINENO"' ERR

ADA_CLUST_S="${ADA_CLUST_S:-"ada/cluster"}"

# // Tracer — toggle with ADA_TRACE=1
source "./$ADA_CLUST_S/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

# // light weight working dir manager
DFLT_GITROOT="$HOME/adalovespace"
GITROOT="${ALT_GIT_ROOT:-$DFLT_GITROOT}"
if [ "$(pwd)" != "$GITROOT" ]; then
    _CURDIR="$(pwd)"
    cd "$GITROOT"
fi

# // CWD should be at user's adalovespace clone spot at this point
# // cluster.env vars are static so can source from the git repo
source ./ada/lib/ada-preflight.sh "${BASH_SOURCE[0]}"

# // Wanna do validation first before running ada-strapper.sh to catch issues
# // before start
# Validate required environment variables
required_vars=(
    "ADA_CODESPACE"
    "ADA_CLUST_S"
    "ADA_CLUSTER"
    "CAROLINE_CV"
)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        ada-logger oof "ERROR: $var environment variable is not set"
        exit 1
    fi
done

if [ ! -d "$ADA_CLUSTER" ]; then
    if [ ! -d "$ADA_CODESPACE" ]; then
        ada-logger oof "ERROR: $ADA_CODESPACE not found"
        exit 1
    fi
    ada-logger oof "ERROR: $ADA_CLUSTER not found, but $ADA_CODESPACE appears to be available"
    exit 1
fi

# Validate required scripts
required_scripts=(
    "$ADA_CLUSTER/core/node_strapper.sh"
    "$ADA_CLUSTER/core/build.sh"
    "$ADA_CLUSTER/nodes/caroline-v/build.sh"
    "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"
)
for script in "${required_scripts[@]}"; do
    if [ ! -f "$script" ]; then
        ada-logger oof "ERROR: $script not found"
        exit 1
    fi
done

# // Using git-root code to bootstrap the node codespace, which will
# // serve as production runtime env
set -a
source "./$ADA_CLUST_S/core/node_strapper.sh" "caroline-v"
set +a

sudo "$ADA_CLUSTER/core/build.sh" "$CAROLINE_CV"
sudo "$ADA_CLUSTER/nodes/caroline-v/build.sh"
sudo "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi

if [[ -t 0 ]]; then
    echo -n "Reboot? [y/N] " && read -r -t 30 yn
    if [[ "${yn,,}" == y ]]; then
        sudo reboot
    fi
else
    ada-logger main "Non-interactive mode: skipping reboot"
    ada-logger yay "Caroline-V build complete, clear skies!"
fi

# // Copyright 2026 Drew Vandagriff
# //
# // Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# // http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# // <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# // option. This file may not be copied, modified, or distributed
# // except according to those terms.
