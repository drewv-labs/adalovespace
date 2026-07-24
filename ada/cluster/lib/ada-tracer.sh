#!/usr/bin/env bash
# AdaLovespace Tracer — Toggle `set -x` project-wide via ADA_TRACE=1
# Usage: source ./ada/cluster/lib/ada-tracer.sh
#   or : ada-tracer <level>  (e.g. ada-tracer 1)

ADA_TRACE_LEVEL="${1:-0}"

if [[ "$ADA_TRACE_LEVEL" == "1" ]]; then
    set -x
    # Make trace output readable — shows file/line before each command
    export PS4='+ ${BASH_SOURCE[0]%/*}/$(basename "${BASH_SOURCE[0]}"):${LINENO} > '
fi
