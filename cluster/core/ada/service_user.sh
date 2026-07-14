#!/usr/bin/env bash
# ==============================================================================
# Script: setup_ada_service_user.sh
# Purpose: Provision the 'ada' runtime service user and configure shared access
# Target: AdaLovespace Edge Nodes (Debian/Ubuntu)
# ==============================================================================

set -euo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

home_dir="/home/${ADA_USER}"

ada-log "sys" "=== Setting up ${ADA_USER} service user"

ada-log "mod" "${ADA_GRAY}--> 1. Creating ${ADA_USER} user and group..."
# Create user with a valid home directory (needed for Python venvs/configs)
# but assign /bin/bash for systemd execution context.
if id "${ADA_USER}" &>/dev/null; then
  ada-log "debug" "User ${ADA_USER} already exists. Skipping creation."
else
  useradd --create-home --home-dir "${home_dir}" --shell /bin/bash "${ADA_USER}"
  ada-log "debug" "Created user: ${ADA_USER}"
fi

ada-log "mod" "${ADA_GRAY}--> 2. Assigning ${ADA_USER} to hardware groups..."
# Standard Debian hardware groups for astrophotography & edge computing
# (serial ports, USB cameras, GPIO pins, video devices, audio/I2C/SPI if present)
hardware_groups="dialout,video,plugdev,tty"

# Dynamically add optional hardware groups if they exist on this specific kernel/OS
for opt_group in gpio i2c spi audio input; do
  if getent group "${opt_group}" >/dev/null; then
    hardware_groups="${hardware_groups},${opt_group}"
  fi
done

usermod -a -G "${hardware_groups}" "${ADA_USER}"
ada-log "debug" "Assigned ${ADA_USER} to groups: ${hardware_groups}"

ada-log "mod" "${ADA_GRAY}--> 3. Configuring collaborative group permissions..."
# Add the admin user to the 'ada' group so you can manage files
if id "${ADA_ADMN}" &>/dev/null; then
  usermod -a -G "${ADA_USER}" "${ADA_ADMN}"
  ada-log "debug" "Added ${ADA_ADMN} to the '${ADA_USER}' group for shared workspace access."
else
  ada-log "warn" "Warning: Admin user '${ADA_ADMN}' not found. Skipping group join."
fi

ada-log "mod" "${ADA_GRAY}--> 4. Provisioning directory structure and applying SetGID magic..."
# Create application and log directories
mkdir -p "${ADA_LOCAL_LOGS}"

# Set ownership: root owner, 'ada' group
chown -R root:"${ADA_USER}" "${ADA_ROOT}" "${ADA_LOCAL_LOGS}"

# Set permissions: 2775 (rwxrwsr-x)
# The '2' is the SetGID bit: any new file created in these folders automatically
# inherits the 'ada' group, preventing permission lockouts between admn and ada!
chmod -R 2775 "${ADA_ROOT}" "${ADA_LOCAL_LOGS}"

# Ensure standard secure permissions on the service user's home directory
chown -R "${ADA_USER}:${ADA_USER}" "${home_dir}"
chmod 750 "${home_dir}"

ada-log "success" "=== ${ADA_USER} setup complete! Structure ready for deployment."
