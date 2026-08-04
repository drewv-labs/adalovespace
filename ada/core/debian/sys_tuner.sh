#!/usr/bin/env bash
# This script disables various services and
# tweaks settings to optimize power usage on a Debian-based system.

set -euo pipefail
ADACODESPACE="${ADACODESPACE:-/opt/adalovespace}"

if command -v ada-preflight; then
    ada-preflight "$BASH_SOURCE"
else
    source "$ADACODESPACE/ada/lib/ada-preflight.sh" "$BASH_SOURCE"
fi

# // Tracer — toggle with ADA_TRACE=1
source "$ADACODESPACE/ada/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

# // Arg-Switches
switches=(
    no_power_tune
    no_sudoers_tune
    keep_bluetooth
    keep_wifi
    keep_modemmanager
    keep_storage_spammer
    keep_unattended_upgrades
)
source arg-switches "${switches[@]}"


# // Funcs
_purge_bluetooth() {
    ada-logger mod "=== Purging Bluetooth"
    sudo systemctl disable --now bluetooth.service
    sudo apt-mark unhold bluez -y
    sudo apt purge bluez -y
    ada-logger yay "=== Goodbye Bluetooth"
}

_purge_wifi() {
    ada-logger mod "=== Purging Wi-Fi"
    sudo systemctl disable --now wpa_supplicant.service
    sudo apt-mark unhold wpasupplicant -y
    sudo apt purge wpasupplicant -y
    ada-logger yay "=== Bye-bye Wi-Fi"
}

_purge_modemmanager() {
    ada-logger mod "=== Purging ModemManager"
    sudo systemctl disable --now ModemManager.service
    sudo apt purge modemmanager -y
    ada-logger yay "=== Goodbye ModemManager"
}

_purge_storage_spammer() {
    ada-logger mod "=== Purging Multipathd Storage Spammer"
    sudo systemctl disable --now multipathd.service multipathd.socket
    sudo apt purge multipath-tools -y
    ada-logger yay "=== Goodbye Multipathd Storage Spammer"
}

_purge_unattended_upgrades() {
    ada-logger mod "=== Purging Unattended Upgrades Service"
    sudo systemctl disable --now unattended-upgrades.service
    sudo systemctl disable --now apt-daily.timer
    sudo systemctl disable --now apt-daily-upgrade.timer
    ada-logger yay "=== Goodbye Unattended Upgrades Services"
}

_tune_power_settings() {
    ada-logger mod "=== Tuning Power Settings"
    settings=(
        "sleep.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
    )
    sudo systemctl mask "${settings[@]}"
    ada-logger yay "=== Power Settings Go Brrr"
}

_tune_sudoers() {
    sudoers_file="/etc/sudoers.d/010_${ADAUSR_ADM}_nopasswd"

    ada-logger mod "=== Configuring passwordless sudo for $ADAUSR_ADM"

    # 1. Write the rule atomically into the drop-in directory
    echo "$ADAUSR_ADM ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null

    # 2. Enforce strict permissions (Must be 0440 or sudo will reject it)
    sudo chmod 0440 "$sudoers_file"

    # 3. Validate the syntax safely before completing the build
    if ! sudo visudo -cf "$sudoers_file"; then
        ada-logger oof "Malformed sudoers syntax detected! Removing file to prevent system lockout."
        sudo rm -f "$sudoers_file"
        exit 1
    fi
    ada-logger yay "=== Passwordless sudo enabled for $ADAUSR_ADM"
}

ada-logger sys "=== Debian Core System Tuner Started"

# // Tunes
arg-switch-if no_power_tune false _tune_power_settings
arg-switch-if no_sudoers_tune false _tune_sudoers

# // Optional Purges
set +e
arg-switch-if keep_bluetooth false _purge_bluetooth
arg-switch-if keep_wifi false _purge_wifi
arg-switch-if keep_modemmanager false _purge_modemmanager
arg-switch-if keep_storage_spammer false _purge_storage_spammer
arg-switch-if keep_unattended_upgrades false _purge_unattended_upgrades
set -e


ada-logger yay "=== Debian Core System Tuner Completed"
