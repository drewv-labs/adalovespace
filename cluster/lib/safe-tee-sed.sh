#!/bin/bash
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

if grep -q -- "$pattern" "$target"; then
    if ! $sudo_cmd sed -i "/${pattern}/c\\${data}" "$target"; then
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
