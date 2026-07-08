#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

TARGET_USER="drew"
SUDOERS_FILE="/etc/sudoers.d/010_${TARGET_USER}_nopasswd"

echo "=== Configuring passwordless sudo for ${TARGET_USER} ==="

# 1. Write the rule atomically into the drop-in directory
echo "${TARGET_USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee "${SUDOERS_FILE}" > /dev/null

# 2. Enforce strict permissions (Must be 0440 or sudo will reject it)
sudo chmod 0440 "${SUDOERS_FILE}"

# 3. Validate the syntax safely before completing the build
if ! sudo visudo -cf "${SUDOERS_FILE}"; then
    echo "CRITICAL ERROR: Malformed sudoers syntax detected! Removing file to prevent system lockout."
    sudo rm -f "${SUDOERS_FILE}"
    exit 1
fi

echo "=== Passwordless sudo successfully configured and verified ==="
