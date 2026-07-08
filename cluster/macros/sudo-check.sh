#!/bin/bash
# Global Ada Lovespace Sudo Sentinel
# Usage: source /usr/local/bin/sudo-check

if [[ "${EUID}" -ne 0 ]]; then
    echo "FATAL: [sudo-check] This script must be run as root." >&2
    # 'return' safely exits the sourced script;
    # 'exit' kills the parent shell.
    return 1 2>/dev/null || exit 1
fi
