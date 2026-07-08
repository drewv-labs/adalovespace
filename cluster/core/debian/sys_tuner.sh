#!/bin/bash
set -euxo pipefail
source sudo-check


# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

# Get the directory of this script
debmods="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

${debmods}/ada_prompt_ps1.sh
${debmods}/disable_unattended_upgrades.sh
${debmods}/nuke_modemmanager.sh
${debmods}/nuke_radios.sh
${debmods}/nuke_storage_spammer.sh
${debmods}/tune_power_mode.sh
${debmods}/tune_sudoers.sh
