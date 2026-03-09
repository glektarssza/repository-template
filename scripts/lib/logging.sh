# shellcheck shell=bash

if ! functions get_script_dir > /dev/null 2>&1; then
    function get_script_dir() {
        pushd . > /dev/null 2>&1
        local SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
        while [[ -L "${SCRIPT_PATH}" ]]; do
            cd "$(dirname -- "${SCRIPT_PATH}")" || return 1
            SCRIPT_PATH="$(readlink -f -- "$SCRIPT_PATH")"
        done
        cd "$(dirname -- "$SCRIPT_PATH")" > /dev/null || return 1
        SCRIPT_PATH="$(pwd)"
        # shellcheck disable=SC2164
        popd > /dev/null 2>&1
        echo "${SCRIPT_PATH}"
        return 0
    }
else
    export -f get_script_dir
fi

if [[ -z "${_LIB_PATH}" ]]; then
    _LIB_PATH="$(get_script_dir)"
fi

if [[ -n "${_LIB_LOGGING_GUARD+x}" ]]; then
    return 0
fi
declare _LIB_LOGGING_GUARD

# shellcheck source=./sgr.sh
source "${_LIB_PATH}/sgr.sh"

# Log an error message to the standard error stream.
function lib::log::error() {
    lib::sgr::8bit::foreground "196" >&2 && printf "[ERROR]" >&2 && lib::sgr::reset >&2 \
        && printf " %s\n" "$*" >&2
    return $?
}

# Log a warning message to the standard output stream.
function lib::log::warn() {
    lib::sgr::8bit::foreground "214" && printf "[WARN]" && lib::sgr::reset \
        && printf " %s\n" "$*"
    return $?
}

# Log an information message to the standard output stream.
function lib::log::info() {
    lib::sgr::8bit::foreground "111" && printf "[INFO]" && lib::sgr::reset \
        && printf " %s\n" "$*"
    return $?
}

# Log a verbose message to the standard output stream.
function lib::log::verbose() {
    if [[ ! -n "${VERBOSE}" || ! "${VERBOSE,,}" =~ 1|true ]]; then
        return 0
    fi
    lib::sgr::8bit::foreground "171" && printf "[VERBOSE]" && lib::sgr::reset \
        && printf " %s\n" "$*"
    return $?
}
