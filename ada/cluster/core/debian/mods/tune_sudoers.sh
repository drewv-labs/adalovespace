#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

sudoers_file="/etc/sudoers.d/010_${ADAUSR_ADM}_nopasswd"

ada-log mod "=== Configuring passwordless sudo for $ADAUSR_ADM"

# 1. Write the rule atomically into the drop-in directory
echo "$ADAUSR_ADM ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null

# 2. Enforce strict permissions (Must be 0440 or sudo will reject it)
sudo chmod 0440 "$sudoers_file"

# 3. Validate the syntax safely before completing the build
if ! sudo visudo -cf "$sudoers_file"; then
    ada-log oof "Malformed sudoers syntax detected! Removing file to prevent system lockout."
    sudo rm -f "$sudoers_file"
    exit 1
fi
