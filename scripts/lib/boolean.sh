if [[ -z ${_LIB_PATH} ]]; then
    if ! SCRIPT_DIR="$(
        function get_script_dir() {
            pushd . 2>&1 > /dev/null || return 1
            local SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
            while [[ -L ${SCRIPT_PATH} ]]; do
                cd "$(dirname -- "${SCRIPT_PATH}")" || return 2
                SCRIPT_PATH="$(readlink -e -- "$SCRIPT_PATH")"
            done
            cd "$(dirname -- "$SCRIPT_PATH")" > /dev/null || return 2
            SCRIPT_PATH="$(pwd)"
            popd 2>&1 > /dev/null || return 3
            echo "${SCRIPT_PATH}"
            return 0
        }
        get_script_dir
    )"; then
        return 1
    fi

    if [[ -z ${_LIB_PATH} ]]; then
        _LIB_PATH="$(readlink -e -- "${SCRIPT_DIR}")"
    fi
fi

if [[ -n ${_LIB_BOOLEAN_GUARD+x} ]]; then
    return 0
fi
declare _LIB_BOOLEAN_GUARD

# The numerical value considered to be "true".
export TRUE=0

# The numerical value considered to be "false".
export FALSE=1

# Get whether the input value is truthy ("0" or the string "true", lower or upper
# case.)
# === Inputs ===
# `$1` - The value to check.
# === Returns ===
# `0` - If the value is truthy.
# `1` - If the value is not truthy.
function lib::boolean::is_truthy() {
    if grep --quiet --extended-regexp --ignore-case "${TRUE}|true" <<< "${1}"; then
        # shellcheck disable=SC2086
        return ${TRUE}
    fi
    # shellcheck disable=SC2086
    return ${FALSE}
}

# Get whether the input value is truthy (any numeric value other than "1" or any
# string other than the string "true", lower or uppercase.)
# === Inputs ===
# `$1` - The value to check.
# === Returns ===
# `0` - If the value is falsy.
# `1` - If the value is not falsy.
function lib::boolean::is_falsy() {
    if ! lib::boolean::is_truthy "${1}"; then
        # shellcheck disable=SC2086
        return ${TRUE}
    fi
    # shellcheck disable=SC2086
    return ${FALSE}
}
