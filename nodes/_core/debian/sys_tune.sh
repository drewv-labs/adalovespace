#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

# Get the directory of this script
DEB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


${DEB}/disable_unattended_upgrades.sh
${DEB}/nuke_modemmanager.sh
${DEB}/nuke_radios.sh
${DEB}/nuke_storage_spammer.sh
${DEB}/tune_power_mode.sh
