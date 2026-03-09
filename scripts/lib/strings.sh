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

if [[ -n "${_LIB_STRINGS_GUARD+x}" ]]; then
    return 0
fi
declare _LIB_STRINGS_GUARD

# Convert a string to all lower case.
# === Inputs ===
# `$1` - The string to convert.
# === Outputs ===
# The converted string.
# === Returns ===
# `0` - The operation succeeded.
# `*` - The operation failed.
function to_lower_case() {
    if ! echo "$1" | tr '[:upper:]' '[:lower:]'; then
        return 1
    fi
    return 0
}

# Convert a string to all upper case.
# === Inputs ===
# `$1` - The string to convert.
# === Outputs ===
# The converted string.
# === Returns ===
# `0` - The operation succeeded.
# `*` - The operation failed.
function to_upper_case() {
    if ! echo "$1" | tr '[:lower:]' '[:upper:]'; then
        return 1
    fi
    return 0
}
