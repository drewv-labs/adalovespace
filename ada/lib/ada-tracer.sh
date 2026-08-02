#!/usr/bin/env bash
set -euo pipefail

# AdaLovespace Tracer — Toggle `set -x` project-wide via ADA_TRACE=1
# Usage: source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"
#   or : ada-tracer "${ADA_TRACE:-0}"

if [[ "${1:-${ADA_TRACE:-0}}" == "1" ]]; then
    set -x
    # Make trace output readable — shows file/line before each command
    export PS4='+ ${BASH_SOURCE[0]%/*}/$(basename "${BASH_SOURCE[0]}"):${LINENO} > '
fi
