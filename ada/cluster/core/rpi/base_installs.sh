#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log sys "=== RaspberryPi Base Installs"

"$ADA_CLUSTER/core/debian/base_installs.sh"
