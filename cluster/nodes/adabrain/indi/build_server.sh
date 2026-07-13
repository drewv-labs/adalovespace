#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_PLUM}=== Building INDI Web Server ==="

${ADA_CLUSTER}/core/debian/mods/install_indiweb.sh
