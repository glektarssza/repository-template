# shellcheck shell=bash

# Get the directory the script is running from.
# === Outputs ===
# The path to the directory the script is running from.
# === Returns ===
# `0` - the function succeeded.
# `1` - a `cd` call failed.
# `2` - a `popd` call failed.
function get_script_dir() {
    pushd . >/dev/null
    local SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
    while [[ -L "${SCRIPT_PATH}" ]]; do
        cd "$(dirname -- "${SCRIPT_PATH}")" || return 1
        SCRIPT_PATH="$(readlink -f -- "$SCRIPT_PATH")"
    done
    cd "$(dirname -- "$SCRIPT_PATH")" >/dev/null || return 1
    SCRIPT_PATH="$(pwd)"
    # shellcheck disable=SC2164
    popd >/dev/null 2>&1
    echo "${SCRIPT_PATH}"
    return 0
}

if ! SCRIPT_DIR="$(get_script_dir)"; then
    return 1
fi
if [[ -z "${_LIB_PATH}" ]]; then
    _LIB_PATH="${SCRIPT_DIR}"
fi

if [[ -n "${_LIB_LOGGING}" ]]; then
    return 0
fi
declare _LIB_LOGGING="loaded"

source "${_LIB_PATH}/sgr.sh"

# Log an error message to the standard error stream.
function log_error() {
    sgr_8bit_fg "196" >&2 && printf "[ERROR]" >&2 && sgr_reset >&2 &&
        printf " %s\n" "$*" >&2
    return $?
}

# Log a warning message to the standard output stream.
function log_warning() {
    sgr_8bit_fg "214" && printf "[WARN]" && sgr_reset &&
        printf " %s\n" "$*"
    return $?
}

# Log an information message to the standard output stream.
function log_info() {
    sgr_8bit_fg "111" && printf "[INFO]" && sgr_reset &&
        printf " %s\n" "$*"
    return $?
}

# Log a verbose message to the standard output stream.
function log_verbose() {
    if [[ ! -n "${VERBOSE}" || ! "${VERBOSE,,}" =~ 1|true ]]; then
        return 0
    fi
    sgr_8bit_fg "171" && printf "[VERBOSE]" && sgr_reset &&
        printf " %s\n" "$*"
    return $?
}
