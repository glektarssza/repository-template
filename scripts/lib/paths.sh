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

if [[ -n ${_LIB_PATHS_GUARD+x} ]]; then
    return 0
fi
declare _LIB_PATHS_GUARD

# shellcheck source=./boolean.sh
source "${_LIB_PATH}/boolean.sh"

# Get a path relative to another path.
# === Inputs ===
# `$1` - The path to get relative to the other path.
# `$2` - The path to use as the base to get the first input relative to.
# === Outputs ===
# The path of the first input, relative to the second input.
# === Returns ===
# `0` - If the command succeeded.
# `...` - If any errors occurred.
function lib::paths::relative_path() {
    local REPLY
    set -- "${1%/}/" "${2%/}/"
    while [ "$1" ] && [ "$2" = "${2#"$1"}" ]; do
        set -- "${1%/?*/}/" "$2" "../$3"
    done
    REPLY="${2#"$1"}"
    if [ "${REPLY#/}" ]; then
        REPLY="${REPLY%/}"
    else
        REPLY="${REPLY:-.}"
    fi
    echo "${REPLY}"
    # shellcheck disable=SC2086
    return ${TRUE}
}
