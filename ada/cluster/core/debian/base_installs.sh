#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log sys "=== Debian Base Installs"

check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        ada-log debug "=== $1 not found, installing..."
        "$ADA_CLUSTER/core/debian/mods/$2"
    else
        ada-log debug "=== $1 found, skipping install."
    fi
}

check_cmd uv install_uv_root.sh
check_cmd stress-ng install_stress_ng.sh
