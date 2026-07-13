#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing INDI Web Server"

sudo apt install indiweb
echo ""
