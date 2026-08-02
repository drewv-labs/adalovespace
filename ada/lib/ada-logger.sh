#!/usr/bin/env bash
# AdaLovespace Central Logging Utility
# Usage: ada-logger <prefix> <message> [log_file]

set -euo pipefail

# Resolve and source cluster.env if not already present
if [[ -z "${ADA_PLUM:-}" ]]; then
    _candidate="$(cd "$(dirname "$0")" && pwd)"
    while [[ "$_candidate" != "/" ]]; do
        [[ -f "$_candidate/ada/cluster.env" ]] && source "$_candidate/ada/cluster.env" && break
        _candidate="$(dirname "$_candidate")"
    done
fi

LOG_PREFIX="$1"
LOG_MSG="$2"
LOG_FILE="${3:-}"
LOG_COLOR=""

if [[ -n "$LOG_PREFIX" ]]; then
    case ${LOG_PREFIX,,} in
        t1|main)
            LOG_COLOR="$ADA_PLUM"
            ;;
        t2|app|sys)
            LOG_COLOR="$ADA_BLU1"
            ;;
        t3|mod)
            LOG_COLOR="$ADA_BLU2"
            ;;
        oof|error|fatal)
            LOG_COLOR="$OOF_RED"
            ;;
        yay|success|complete)
            LOG_COLOR="$YAY_GRN"
            ;;
        eh|warn|debug)
            LOG_COLOR="$ADA_GRAY"
            ;;
        *)
            LOG_COLOR="$ADA_WEIS"
            ;;
    esac
fi

timestamp=$(date +"%Y-%m-%dT%H:%M:%S.%3N")
message="[$(hostname)]:$LOG_PREFIX $timestamp $LOG_MSG"

if [[ -n "$LOG_FILE" ]]; then
    tee -a "$LOG_FILE" <<< "${LOG_COLOR}${message}${ADA_RSET}"
else
    tee <<< "${LOG_COLOR}${message}${ADA_RSET}"
fi
