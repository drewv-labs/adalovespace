#!/usr/bin/env bash
# AdaLovespace Central Logging Utility
# Usage: ada-log <prefix> <message> [log_file]

LOG_PREFIX="${1}"
LOG_MSG="${2}"
LOG_FILE="${3:-}"
LOG_COLOR=""

if [[ -n "${LOG_PREFIX}" ]]; then
    case ${LOG_PREFIX,,} in
        t1|main)
            LOG_COLOR="${ADA_PLUM}"
            ;;
        t2|app|sys)
            LOG_COLOR="${ADA_BLU1}"
            ;;
        t3|mod)
            LOG_COLOR="${ADA_BLU2}"
            ;;
        oof|error|fatal)
            LOG_COLOR="${OOF_RED}"
            ;;
        yay|success|complete)
            LOG_COLOR="${YAY_GRN}"
            ;;
        eh|warn|debug)
            LOG_COLOR="${ADA_GRAY}"
            ;;
        *)
            LOG_COLOR="${ADA_WEIS}"
            ;;
    esac
fi

timestamp=$(date +"%Y-%m-%dT%H:%M:%S.%3N")
message="[$(hostname)]:${LOG_PREFIX} ${timestamp} ${LOG_MSG}"

if [[ -n "${LOG_FILE}" ]]; then
    tee -a "${LOG_FILE}" <<< "${LOG_COLOR}${message}${ADA_RSET}"
else
    tee <<< "${LOG_COLOR}${message}${ADA_RSET}"
fi
