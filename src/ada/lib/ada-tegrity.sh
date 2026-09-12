#!/usr/bin/env bash
# // usage (assumes linked to /usr/local/bin via ada/cluster/core/node_strapper.sh)
# // tegrity-checks=("a -a", "b -bs")
# // ada-tegrity tegrity-checks

set -euo pipefail

# Source ada-tracer for verbosity control
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

# Check if ada-logger is defined
if ! command -v ada-logger &> /dev/null; then
    echo "FATAL: ada-logger not found. Please ensure it is available in your PATH."
    exit 1
fi

# Parse arguments for verbose mode
verbose=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            verbose=1
            shift
            ;;
        *)
            break
            ;;
    esac
done

integrity_checks=("$@")

err=0
for tegrity in "${integrity_checks[@]}"; do
    if [[ "$verbose" -eq 1 ]]; then
        ada-logger info "Running integrity check: $tegrity"
    fi
    if ! eval "$tegrity" &> /dev/null; then
        ada-logger oof "FAILED INTEGRITY CHECK: $tegrity"
        err=$((err+1))
    elif [[ "$verbose" -eq 1 ]]; then
        ada-logger info "Passed integrity check: $tegrity"
    fi
done

if [ "$err" -gt 0 ]; then
    ada-logger oof "FAILED $err INTEGRITY CHECKS"
    exit 1
fi

return 0
