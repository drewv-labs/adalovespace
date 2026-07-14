#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "app" "=== Building XFCE + LightDM GUI ==="

${ADA_CLUSTER}/core/debian/modes/install_xfce_lightdm_stack.sh
${ADA_CLUSTER}/nodes/margaret/xfce/config_passwordless_login.sh
