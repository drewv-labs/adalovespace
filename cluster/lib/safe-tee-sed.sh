#!/usr/bin/env bash
# safe-tee-sed — Idempotent config update via sed replace or tee append.
#
# Usage:
#   safe-tee-sed TARGET PATTERN DATA [SUDO]
#
# Examples:
#   safe-tee-sed /etc/exports "^/mnt/data" "/mnt/data *(rw,sync,no_subtree_check)"
#   safe-tee-sed /etc/exports "^/mnt/data" "/mnt/data *(rw,sync)" yes
#
# Exit codes: 0 = success, 1 = failure (target missing or command failed)

set -euo pipefail

target="${1:?usage: safe-tee-sed TARGET PATTERN DATA [SUDO]}"
pattern="${2:?usage: safe-tee-sed TARGET PATTERN DATA [SUDO]}"
data="${3:?usage: safe-tee-sed TARGET PATTERN DATA [SUDO]}"
use_sudo="${4:-no}"

if [ ! -f "$target" ]; then
    echo "${ADA_RED}FATAL: [safe-tee-sed] Target file not found: $target" >&2
    exit 1
fi

[ "$use_sudo" == "yes" ] && sudo_cmd="sudo" || sudo_cmd=""

# Function to find a safe delimiter for sed
find_safe_delimiter() {
    local pattern="$1"
    local data="$2"
    local delimiters='/%!@#$^&*()-_=+[]{}|;:,.<>?`~'
    local default_delim="/"

    # Check each character in delimiters to find a safe one
    for (( i=0; i<${#delimiters}; i++ )); do
        local delim="${delimiters:$i:1}"
        if [[ "$pattern" != *"$delim"* && "$data" != *"$delim"* ]]; then
            echo "$delim"
            return 0
        fi
    done

    # If no safe delimiter is found, use default /
    echo "$default_delim"
}

# Find a safe delimiter
safe_delim=$(find_safe_delimiter "$pattern" "$data")

if grep -qF -- "$pattern" "$target"; then
    if ! $sudo_cmd sed -i "${safe_delim}${pattern}${safe_delim}c\\${data}${safe_delim}" "$target"; then
        echo "${ADA_RED}FATAL: [safe-tee-sed] sed failed for pattern '$pattern' in $target" >&2
        exit 1
    fi
else
    if ! printf '%s\n' "$data" | $sudo_cmd tee -a "$target" >/dev/null; then
        echo "${ADA_RED}FATAL: [safe-tee-sed] tee failed for $target" >&2
        exit 1
    fi
fi

exit 0
