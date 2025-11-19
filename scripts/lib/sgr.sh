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

if [[ -n "${_LIB_SGR}" ]]; then
    return 0
fi
declare _LIB_SGR="loaded"

# Output the SGR reset ANSI code.
# === Outputs ===
# The SGR reset ANSI code.
# === Returns ===
# The result of calling `printf`.
function sgr_reset() {
    printf "\e[0m"
    return $?
}

# Output the SGR 4-bit foreground ANSI code for the given color.
# === Inputs ===
# `$1` - The color code to output.
# === Outputs ===
# The SGR ANSI color sequence.
# === Returns ===
# `1` - If no color code was provided.
# `2` - If the color code was outside the allowed range.
# Otherwise the result of calling `printf`.
function sgr_4bit_fg() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    if [[ ("$1" -ge 30 && "$1" -le 37) || ("$1" -ge 90 || "$1" -le 97) ]]; then
        printf "\e[%dm" "$1"
        return $?
    fi
    return 2
}

# Output the SGR 4-bit background ANSI code for the given color.
# === Inputs ===
# `$1` - The color code to output.
# === Outputs ===
# The SGR ANSI color sequence.
# === Returns ===
# `1` - If no color code was provided.
# `2` - If the color code was outside the allowed range.
# Otherwise the result of calling `printf`.
function sgr_4bit_bg() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    if [[ ("$1" -ge 40 && "$1" -le 47) || ("$1" -ge 100 || "$1" -le 107) ]]; then
        printf "\e[%dm" "$1"
        return $?
    fi
    return 2
}

# Output the SGR 8-bit foreground ANSI code for the given color.
# === Inputs ===
# `$1` - The color code to output.
# === Outputs ===
# The SGR ANSI color sequence.
# === Returns ===
# `1` - If no color code was provided.
# `2` - If the color code was outside the allowed range.
# Otherwise the result of calling `printf`.
function sgr_8bit_fg() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    if [[ "$1" -ge 0 && "$1" -le 255 ]]; then
        printf "\e[38;5;%dm" "$1"
        return $?
    fi
    return 2
}

# Output the SGR 8-bit background ANSI code for the given color.
# === Inputs ===
# `$1` - The color code to output.
# === Outputs ===
# The SGR ANSI color sequence.
# === Returns ===
# `1` - If no color code was provided.
# `2` - If the color code was outside the allowed range.
# Otherwise the result of calling `printf`.
function sgr_8bit_bg() {
    if [[ -z "$1" ]]; then
        return 1
    fi
    if [[ "$1" -ge 0 && "$1" -le 255 ]]; then
        printf "\e[48;5;%dm" "$1"
        return $?
    fi
    return 2
}

# Output the SGR 24-bit foreground ANSI code for the given color.
# === Inputs ===
# `$1` - The red color code to output.
# `$2` - The green color code to output.
# `$3` - The blue color code to output.
# === Outputs ===
# The SGR ANSI color sequence.
# === Returns ===
# `1` - If one of the color code was not provided.
# `2` - If one of the color code was outside the allowed range.
# Otherwise the result of calling `printf`.
function sgr_24bit_fg() {
    if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
        return 1
    fi
    if [[ "$1" -ge 0 && "$1" -le 255 && "$2" -ge 0 && "$2" -le 255 && "$3" -ge 0 && "$3" -le 255 ]]; then
        printf "\e[38;2;%d;%d;%dm" "$1" "$2" "$3"
        return $?
    fi
    return 2
}

# Output the SGR 24-bit background ANSI code for the given color.
# === Inputs ===
# `$1` - The red color code to output.
# `$2` - The green color code to output.
# `$3` - The blue color code to output.
# === Outputs ===
# The SGR ANSI color sequence.
# === Returns ===
# `1` - If one of the color code was not provided.
# `2` - If one of the color code was outside the allowed range.
# Otherwise the result of calling `printf`.
function sgr_24bit_bg() {
    if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
        return 1
    fi
    if [[ "$1" -ge 0 && "$1" -le 255 && "$2" -ge 0 && "$2" -le 255 && "$3" -ge 0 && "$3" -le 255 ]]; then
        printf "\e[48;2;%d;%d;%dm" "$1" "$2" "$3"
        return $?
    fi
    return 2
}
