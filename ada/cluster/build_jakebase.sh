#!/usr/bin/env bash
# ================================================================
# Name: build_jakebase.sh
# Version: 1.0.0
# Description: Bootstrapper for setting up Jakebase production environment
# Author: Drew Vandagriff
# ==============================================================

set -euo pipefail

# Trap for error handling
trap 'echo "ERROR: Script failed at line $LINENO"; rollback_environment' ERR

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
source ./ada/cluster.env

# // Wanna do validation first before running ada-strapper.sh to catch issues
# // before start
# Validate required environment variables
required_vars=(
    "ADA_CODESPACE",
    "ADA_CLUST_S",
    "ADA_CLUSTER",
    "JAKEBASE_HW"
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
    ada-logger oof "ERROR: $ADA_CLUSTER not found, but $ADA_CODESPACE is appears to be available"
    exit 1
fi

# Validate required scripts
required_scripts=(
    "$ADA_CLUSTER/core/build.sh"
    "$ADA_CLUSTER/nodes/jakebase/build.sh"
    "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"
)
for script in "${required_scripts[@]}"; do
    if [ ! -f "$script" ]; then
        ada-logger oof "ERROR: $script not found"
        exit 1
    fi
done

# // Backup environment before starting the build process
backup_environment() {
    ada-logger main "Creating backup of current environment..."
    BACKUP_DIR="/tmp/jakebase_backup_$(date +%s)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$GITROOT" "$BACKUP_DIR"
}

# // Restore environment if needed
rollback_environment() {
    ada-logger oof "Restoring environment from backup..."
    rm -rf "$GITROOT"
    mv "$BACKUP_DIR" "$GITROOT"
}

# // Run tests
run_tests() {
    cd /Users/drew/workspace/github.com/dvandagriff/adalovespace/tests
    ./run_tests.sh
    if [ $? -ne 0 ]; then
        ada-logger oof "ERROR: Tests failed. Rolling back environment."
        rollback_environment
        exit 1
    fi
}

# Backup environment before starting the build process
backup_environment

# // Using git-root code to bootstrap the node codespace, which will
# // serve as production runtime env
set -a
source "./$ADA_CLUST_S/lib/ada-strapper.sh" jakebase
set +a

# Run core build script and tests
sudo "$ADA_CLUSTER/core/build.sh" "$JAKEBASE_HW"
run_tests

# Run JakeBase node build script and tests
sudo "$ADA_CLUSTER/nodes/jakebase/build.sh"
run_tests

# Run APT update/upgrade/purge script and tests
sudo "$ADA_CLUSTER/core/apt_update_upgrade_purge.sh"
run_tests

# // restore orig working dir
if [ "$(pwd)" != "$_CURDIR" ]; then
    cd "$_CURDIR"
fi

ada-logger main "JakeBase setup complete."
