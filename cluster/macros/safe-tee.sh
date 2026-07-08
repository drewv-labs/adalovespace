#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

target=$1
pattern=$2
data=$3

# Check if the target file exists
if [ ! -f "$target" ]; then
    echo "Target file not found: $target"
    exit 1
fi
