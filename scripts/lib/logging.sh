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

if [[ -n ${_LIB_LOGGING_GUARD+x} ]]; then
    return 0
fi
declare _LIB_LOGGING_GUARD

# shellcheck source=./sgr.sh
source "${_LIB_PATH}/sgr.sh"
# shellcheck source=./strings.sh
source "${_LIB_PATH}/strings.sh"
# shellcheck source=./boolean.sh
source "${_LIB_PATH}/boolean.sh"

# Format the input.
# === Inputs ===
# `$1` - The message to format.
# `...` - The parameters to inject into the message.
# === Outputs ===
# The formatted message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::format() {
    local -a ARGS
    local MSG
    MSG="${1}"
    shift
    while [[ -n "${1}" ]]; do
        if [[ "${1}" =~ (<eval .*/>) ]]; then
            local EVAL
            EVAL="$(sed -E 's/<eval[[:space:]]+(.*)[[:space:]]*\/>$/\1/' <<< "${1}")"
            ARGS+=("$(eval "${EVAL}")")
        else
            ARGS+=("${1}")
        fi
        shift
    done
    # shellcheck disable=SC2059
    printf "${MSG}" "${ARGS[@]}"
    return $?
}

# Get whether verbose logging is enabled.
# === Returns ===
# `0` - If verbose logging is enabled.
# `1` - If verbose logging is not enabled.
function lib::logging::is_verbose_enabled() {
    lib::boolean::is_truthy "${VERBOSE}"
    return $?
}

# Log an error message to the standard error stream.
# === Inputs ===
# `$1` - The message to log.
# `...` - The parameters to inject into the message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::error() {
    # shellcheck disable=SC2048,2086
    lib::sgr::8bit_fg "196" >&2 && printf "[ERROR] " >&2 && lib::sgr::reset >&2 && printf "%b\n" "$(lib::logging::format "${@}")" >&2
    return $?
}

# Log a warning message to the standard output stream.
# === Inputs ===
# `$1` - The message to log.
# `...` - The parameters to inject into the message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::warn() {
    # shellcheck disable=SC2048,2086
    lib::sgr::8bit_fg "214" && printf "[WARN] " && lib::sgr::reset && printf "%b\n" "$(lib::logging::format "${@}")"
    return $?
}

# Log an information message to the standard output stream.
# === Inputs ===
# `$1` - The message to log.
# `...` - The parameters to inject into the message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::info() {
    # shellcheck disable=SC2048,2086
    lib::sgr::8bit_fg "111" && printf "[INFO] " && lib::sgr::reset && printf "%b\n" "$(lib::logging::format "${@}")"
    return $?
}

# Log a verbose message to the standard output stream.
# === Inputs ===
# `$1` - The message to log.
# `...` - The parameters to inject into the message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::verbose() {
    if ! lib::logging::is_verbose_enabled; then
        return 0
    fi
    # shellcheck disable=SC2048,2086
    lib::sgr::8bit_fg "171" && printf "[VERBOSE] " && lib::sgr::reset && printf "%b\n" "$(lib::logging::format "${@}")"
    return $?
}

# Log a success message to the standard output stream.
# === Inputs ===
# `$1` - The message to log.
# `...` - The parameters to inject into the message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::success() {
    # shellcheck disable=SC2048,2086
    lib::sgr::8bit_fg "118" && printf "%b\n" "$(lib::logging::format "${@}")" && lib::sgr::reset
    return $?
}

# Log a failure message to the standard output stream.
# === Inputs ===
# `$1` - The message to log.
# `...` - The parameters to inject into the message.
# === Returns ===
# `0` - Success
# `1` - Failure
function lib::logging::failure() {
    # shellcheck disable=SC2048,2086
    lib::sgr::8bit_fg "196" && printf "%b\n" "$(lib::logging::format "${@}")" && lib::sgr::reset
    return $?
}
