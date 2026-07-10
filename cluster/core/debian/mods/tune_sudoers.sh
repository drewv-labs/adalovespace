#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

sudoers_file="/etc/sudoers.d/010_${ADA_ADMN}_nopasswd"

echo "${ADA_BLU1}=== Configuring passwordless sudo for ${ADA_ADMN} ==="

# 1. Write the rule atomically into the drop-in directory
echo "${ADA_ADMN} ALL=(ALL) NOPASSWD: ALL" | sudo tee "${sudoers_file}" > /dev/null

# 2. Enforce strict permissions (Must be 0440 or sudo will reject it)
sudo chmod 0440 "${sudoers_file}"

# 3. Validate the syntax safely before completing the build
if ! sudo visudo -cf "${sudoers_file}"; then
    echo "CRITICAL ERROR: Malformed sudoers syntax detected! Removing file to prevent system lockout."
    sudo rm -f "${sudoers_file}"
    exit 1
fi

echo "=== Passwordless sudo successfully configured and verified ==="
