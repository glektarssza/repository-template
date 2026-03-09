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

if [[ -n "${_LIB_GITHUB_GUARD+x}" ]]; then
    return 0
fi
declare _LIB_GITHUB_GUARD
