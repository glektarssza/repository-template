#!/usr/bin/env bash

set +x +e

function setup_vars() {
    #
    declare -a PRE_COMMIT_PATHS
    declare SCRIPT_DIR PROJECT_ROOT DISTRO PRE_COMMIT_INDEX
}

function setup() {
    setup_vars
}

function cleanup_vars() {
    unset SCRIPT_DIR PROJECT_ROOT DISTRO PRE_COMMIT_PATHS PRE_COMMIT_INDEX
}

# Our cleanup function
# shellcheck disable=SC2329
function cleanup() {
    cleanup_vars
}

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

# Prompt the user if it's okay to continue.
# === Inputs ===
# `$1` - The prompt to display.
# `$2` - The default response. Defaults to `y`.
# === Returns ===
# `0` - Okay to continue.
# `1` - Not okay to continue.
# `2` - Some other error.
function prompt_to_continue() {
    local PROMPT="$1"
    local DEFAULT_RESP="${2:-y}"
    local RESP=""
    if [[ -z "${PROMPT}" ]]; then
        log_error "No prompt provided to 'prompt_to_continue'!"
        return 2
    fi
    if [[ "$(to_lower_case "${DEFAULT_RESP}")" == "y" ]]; then
        PROMPT="${PROMPT}\nIs this okay? [Y/n] "
    else
        PROMPT="${PROMPT}\nIs this okay? [y/N] "
    fi
    while true; do
        printf "%b" "${PROMPT}"
        read -r RESP
        case "$(to_lower_case "${RESP:-${DEFAULT_RESP}}")" in
            y) return 0 ;;
            n) return 1 ;;
            *)
                RESP=""
                log_error "Invalid response \"${RESP}\"! Please try again!"
                ;;
        esac
    done
}

setup

# Run our cleanup routine on exit
trap cleanup EXIT

SCRIPT_DIR="$(
    (
        # Get the directory the script is running from.
        # === Outputs ===
        # The path to the directory the script is running from.
        # === Returns ===
        # `0` - the function succeeded.
        # `1` - a `cd` call failed.
        # `2` - a `popd` call failed.
        function get_script_dir() {
            pushd . > /dev/null
            local SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
            while [[ -L "${SCRIPT_PATH}" ]]; do
                cd "$(dirname -- "${SCRIPT_PATH}")" || return 1
                SCRIPT_PATH="$(readlink -f -- "$SCRIPT_PATH")"
            done
            cd "$(dirname -- "$SCRIPT_PATH")" > /dev/null || return 1
            SCRIPT_PATH="$(pwd)"
            popd > /dev/null || return 2
            echo "${SCRIPT_PATH}"
            return 0
        }
        get_script_dir
    )
)"

_LIB_PATH="$(readlink -f -- "${SCRIPT_DIR}/lib/")"

# shellcheck source=./lib/logging.sh
source "${_LIB_PATH}/logging.sh"

# The path to the project root directory
PROJECT_ROOT="$(readlink -f -- "${SCRIPT_DIR}/..")"

# Determine our distribution
DISTRO="$(cat /etc/os-release | grep '^ID' | awk -F'=' '{print $2;}')"

log_verbose "Determined OS distro to be \"${DISTRO}\""

if [[ -n "${CI}" && ! "$*" =~ \s*--force\s* ]]; then
    log_warning "Running in a CI environment, not setting up pre-commit!"
    exit 0
fi

# Locate pre-commit
PRE_COMMIT="$(command -v pre-commit 2> /dev/null)"
if [[ -z "${PRE_COMMIT}" ]]; then
    log_warning "\"pre-commit\" is not installed, attempting to install via \"pipx\"!"
    if ! which pipx > /dev/null 2>&1; then
        log_warning "\"pipx\" is not installed, attempting to install!"
        case "${DISTRO}" in
            arch)
                PACMAN="pacman"
                PACMAN_FLAGS=(-S --noconfirm --needed --asexplicit)
                PACKAGE_NAME="python-pipx"
                ;;
            debian | ubuntu)
                PACMAN=apt
                PACMAN_FLAGS=(install --assume-yes --no-install-recommends)
                PACKAGE_NAME="pipx"
                ;;
        esac
        log_info "We're going to attempt to install \"pipx\", this will require admin permissions!"
        if [[ ! -x "${PACMAN}" ]]; then
            log_warning "Unable to execute \"${PACMAN}\" as we are, trying to elevate..."
            if command -v sudo >&/dev/null; then
                if ! prompt_to_continue "We're about to run 'sudo \"${SHELL}\" -i -c \"${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}\"'." "n"; then
                    log_error "Aborting!"
                    exit 1
                fi
                log_verbose "Trying to elevate via \"sudo\"..."
                sudo --login eval "${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}"
                STATUS_CODE=$?
            elif command -v su >&/dev/null; then
                if ! prompt_to_continue "We're about to run 'su --login --command=\n\"${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}\"'." "n"; then
                    log_error "Aborting!"
                    exit 1
                fi
                log_verbose "Trying to elevate via \"su\"..."
                su --login --command="${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}"
                STATUS_CODE=$?
            else
                log_error "Failed to elevate!"
                exit 1
            fi
        else
            exec "${PACMAN}" "${PACMAN_FLAGS[*]}" pipx
            STATUS_CODE=$?
        fi
        if [[ "${STATUS_CODE}" != "0" ]]; then
            log_verbose "\"${PACMAN}\" exited with code \"${STATUS_CODE}\"!"
            log_error "Failed to install \"pipx\"!"
            exit $STATUS_CODE
        fi
        log_info "\"pipx\" was installed successfully!"
    fi
    pipx install pre-commit
    STATUS_CODE=$?
    if [[ "${STATUS_CODE}" != "0" ]]; then
        log_verbose "\"pipx\" exited with code \"${STATUS_CODE}\"!"
        log_error "Failed to install \"pre-commit\"!"
        exit $STATUS_CODE
    fi
    log_info "\"pre-commit\" was installed successfully!"
    PRE_COMMIT="$(which pre-commit 2> /dev/null)"
    if [[ -z "${PRE_COMMIT}" ]]; then
        log_warning "Still cannot find \"pre-commit\", trying some well-known locations..."
        mapfile -t PRE_COMMIT_PATHS < <(find ~ -maxdepth 4 \( -type f -or -type l \) -name pre-commit -printf '%p\n')
        if [[ "${#PRE_COMMIT_PATHS[@]}" -le 0 ]]; then
            log_error "Failed to locate \"pre-commit\"!"
            exit 1
        fi
        echo -e "Found the following \"pre-commit\" executables:\n$(echo "${PRE_COMMIT_PATHS[*]}" | awk -F' ' '{for(i=1;i<=NF;i+=1){print i": "$i;}}')"
        read -rep "Which one do you want to use? [index] " PRE_COMMIT_INDEX
        while [[ ! "${PRE_COMMIT_INDEX}" =~ [[:digit:]]+ || "${PRE_COMMIT_INDEX}" -lt 0 || "${PRE_COMMIT_INDEX}" -gt "${#PRE_COMMIT_PATHS[@]}" ]]; do
            if [[ -z "${PRE_COMMIT_INDEX}" ]]; then
                PRE_COMMIT_INDEX="1"
                break
            fi
            log_error "Value ${PRE_COMMIT_INDEX} is not valid, try again!"
            echo -e "Found the following \"pre-commit\" executables:\n$(echo "${PRE_COMMIT_PATHS[*]}" | awk -F' ' '{for(i=1;i<=NF;i+=1){print i": "$i;}}')"
            read -rep "Which one do you want to use? [index (default 1)] " PRE_COMMIT_INDEX
        done
        log_verbose "\"pre-commit\" option index \"${PRE_COMMIT_INDEX}\" picked"
        PRE_COMMIT="${PRE_COMMIT_PATHS[(${PRE_COMMIT_INDEX} - 1)]}"
        log_verbose "Selected \"pre-commit\" executable \"${PRE_COMMIT}\""
    fi
else
    log_verbose "\"pre-commit\" found at \"${PRE_COMMIT}\"!"
fi

if ! pushd "${PROJECT_ROOT}" > /dev/null 2>&1; then
    log_error "Failed to enter project root directory!"
    exit 1
fi

log_info "Installing pre-commit hooks..."
printf "%b=== pre-commit output ===%b\n" "$(sgr_8bit_fg 163)" "$(sgr_reset)"
"${PRE_COMMIT}" install --hook-type pre-commit --hook-type pre-push
STATUS_CODE=$?
printf "%b=== pre-commit output ===%b\n" "$(sgr_8bit_fg 163)" "$(sgr_reset)"
log_verbose "\"pre-commit\" exited with code \"${STATUS_CODE}\""
if [[ "${STATUS_CODE}" != "0" ]]; then
    log_error "Failed to install pre-commit hooks!"
    exit $STATUS_CODE
fi

if ! popd > /dev/null 2>&1; then
    log_error "Failed to exit project root directory!"
    exit 1
fi

# On success, exit
exit 0
