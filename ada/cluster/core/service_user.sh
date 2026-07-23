#!/usr/bin/env bash
# ==============================================================================
# Script: setup_ada_service_user.sh
# Purpose: Provision the 'ada' runtime service user and configure shared access
# Target: AdaLovespace Edge Nodes (Debian/Ubuntu)
# ==============================================================================

set -euo pipefail
source ada-preflight "$BASH_SOURCE"

home_dir="/home/$ADAUSR_SRV"

ada-log sys "=== Setting up $ADAUSR_SRV service user"

ada-log mod "--> 1. Creating $ADAUSR_SRV user and group..."
# Create user with a valid home directory (needed for Python venvs/configs)
# but assign /bin/bash for systemd execution context.
if id "$ADAUSR_SRV" &>/dev/null; then
  ada-log debug "User $ADAUSR_SRV already exists. Skipping creation."
else
  useradd --create-home --home-dir "$home_dir" --shell /bin/bash "$ADAUSR_SRV"
  ada-log debug "Created user: $ADAUSR_SRV"
fi

ada-log mod "--> 2. Assigning $ADAUSR_SRV to hardware groups..."
# Standard Debian hardware groups for astrophotography & edge computing
# (serial ports, USB cameras, GPIO pins, video devices, audio/I2C/SPI if present)
hardware_groups="dialout,video,plugdev,tty"

# Dynamically add optional hardware groups if they exist on this specific kernel/OS
for opt_group in gpio i2c spi audio input; do
  if getent group "$opt_group" >/dev/null; then
    hardware_groups="$hardware_groups,$opt_group"
  fi
done

usermod -a -G "$hardware_groups" "$ADAUSR_SRV"
ada-log debug "Assigned $ADAUSR_SRV to groups: $hardware_groups"

ada-log mod "--> 3. Configuring collaborative group permissions..."
# Add the admin user to the 'ada' group so you can manage files
if id "$ADAUSR_ADM" &>/dev/null; then
  usermod -a -G "$ADAUSR_SRV" "$ADAUSR_ADM"
  ada-log debug "Added $ADAUSR_ADM to the '$ADAUSR_SRV' group for shared workspace access."
else
  ada-log warn "Warning: Admin user '$ADAUSR_ADM' not found. Skipping group join."
fi

ada-log mod "--> 4. Provisioning directory structure and applying SetGID magic..."
# Create application and log directories
mkdir -p "$ADA_LOCAL_LOGS"

# Set ownership: root owner, 'ada' group
chown -R root:"$ADAUSR_SRV" "$ADA_ROOT" "$ADA_LOCAL_LOGS"

# Set permissions: 2775 (rwxrwsr-x)
# The '2' is the SetGID bit: any new file created in these folders automatically
# inherits the 'ada' group, preventing permission lockouts between admn and ada!
chmod -R 2775 "$ADA_ROOT" "$ADA_LOCAL_LOGS"

# Ensure standard secure permissions on the service user's home directory
chown -R "$ADAUSR_SRV:$ADAUSR_SRV" "$home_dir"
chmod 750 "$home_dir"
