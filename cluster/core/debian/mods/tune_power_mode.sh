#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Tuning Power Mode"
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
echo ""
