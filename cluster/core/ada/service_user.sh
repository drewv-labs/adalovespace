#!/bin/bash
# ==============================================================================
# Script: setup_ada_service_user.sh
# Purpose: Provision the 'ada' runtime service user and configure shared access
# Target: AdaLovespace Edge Nodes (Debian/Ubuntu)
# ==============================================================================

set -euo pipefall
source ada-preflight "${BASH_SOURCE[0]}"

service_user="ada"
admin_user="drew"
home_dir="/home/${service_user}"
app_dir="/opt/ada"
log_dir="/var/log/ada"

echo "--> 1. Creating ${service_user} user and group..."
# Create user with a valid home directory (needed for Python venvs/configs)
# but assign /bin/bash for systemd execution context.
if id "${service_user}" &>/dev/null; then
  echo "User ${service_user} already exists. Skipping creation."
else
  useradd --create-home --home-dir "${home_dir}" --shell /bin/bash "${service_user}"
  echo "Created user: ${service_user}"
fi

echo "--> 2. Assigning ${service_user} to hardware groups..."
# Standard Debian hardware groups for astrophotography & edge computing
# (serial ports, USB cameras, GPIO pins, video devices, audio/I2C/SPI if present)
hardware_groups="dialout,video,plugdev,tty"

# Dynamically add optional hardware groups if they exist on this specific kernel/OS
for opt_group in gpio i2c spi audio input; do
  if getent group "${opt_group}" >/dev/null; then
    hardware_groups="${hardware_groups},${opt_group}"
  fi
done

usermod -a -G "${hardware_groups}" "${service_user}"
echo "Assigned ${service_user} to groups: ${hardware_groups}"

echo "--> 3. Configuring collaborative group permissions..."
# Add the admin user ('drew') to the 'ada' group so you can manage files
if id "${admin_user}" &>/dev/null; then
  usermod -a -G "${service_user}" "${admin_user}"
  echo "Added ${admin_user} to the '${service_user}' group for shared workspace access."
else
  echo "Warning: Admin user '${admin_user}' not found. Skipping group join."
fi

echo "--> 4. Provisioning directory structure and applying SetGID magic..."
# Create application and log directories
mkdir -p "${app_dir}" "${log_dir}"

# Set ownership: root owner, 'ada' group
chown -R root:"${service_user}" "${app_dir}" "${log_dir}"

# Set permissions: 2775 (rwxrwsr-x)
# The '2' is the SetGID bit: any new file created in these folders automatically
# inherits the 'ada' group, preventing permission lockouts between drew and ada!
chmod -R 2775 "${app_dir}" "${log_dir}"

# Ensure standard secure permissions on the service user's home directory
chown -R "${service_user}:${service_user}" "${home_dir}"
chmod 750 "${home_dir}"

echo "--> Provisioning complete! Structure ready for deployment."
