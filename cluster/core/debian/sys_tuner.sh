#!/bin/bash
# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

debmods="${ADA_ROOT}/cluster/core/debian/mods"

${debmods}/disable_unattended_upgrades.sh
${debmods}/nuke_modemmanager.sh
${debmods}/nuke_radios.sh
${debmods}/nuke_storage_spammer.sh
${debmods}/tune_power_mode.sh
${debmods}/tune_sudoers.sh
