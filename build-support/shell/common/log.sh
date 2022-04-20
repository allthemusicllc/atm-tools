__TERMINAL_COLOR_BLUE="\e[0;34m"
__TERMINAL_COLOR_GREEN="\e[0;32m"
__TERMINAL_COLOR_RED="\e[0;31m"
__TERMINAL_COLOR_YELLOW="\e[0;33m"
__TERMINAL_BOLD="\e[1m"
__TERMINAL_RESET="\e[0m"

log() {
    local MESSAGE="${1}"
    local LEVEL="${2:-INFO}"
    local LEVEL_COLOR="${3:-__TERMINAL_COLOR_GREEN}"

    LEVEL="$(echo ${LEVEL} | tr '[:lower:]' '[:upper:]')"

    # If stdout is a terminal (not in a pipe) use colored output
    if [ -t 1 ]
    then
        LEVEL="${LEVEL_COLOR}${__TERMINAL_BOLD}${LEVEL}${__TERMINAL_RESET}"
        MESSAGE="${LEVEL_COLOR}${MESSAGE}${__TERMINAL_RESET}"
    fi

    echo -e "$(date -u +'%F %T%z')\t${LEVEL}\t${MESSAGE}"
}

debug() {
    local MESSAGE="${1}"

    log "${MESSAGE}" "DEBUG" "${__TERMINAL_COLOR_BLUE}"
}

info() {
    local MESSAGE="${1}"

    log "${MESSAGE}" "INFO" "${__TERMINAL_COLOR_GREEN}"
}

warn() {
    local MESSAGE="${1}"

    log "${MESSAGE}" "WARNING" "${__TERMINAL_COLOR_YELLOW}"
}

error() {
    local MESSAGE="${1}"

    log "${MESSAGE}" "ERROR" "${__TERMINAL_COLOR_RED}"
}
