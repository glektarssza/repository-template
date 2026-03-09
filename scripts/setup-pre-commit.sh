#!/usr/bin/env bash

set +x +e

if ! functions get_script_dir > /dev/null 2>&1; then
    # Get the directory the script is running from.
    # === Outputs ===
    # The path to the directory the script is running from.
    # === Returns ===
    # `0` - the function succeeded.
    # `1` - a `cd` call failed.
    # `2` - a `popd` call failed.
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

# Setup the variables used by the script.
function setup_vars() {
    #
    declare -a PRE_COMMIT_PATHS
    declare SCRIPT_DIR PROJECT_ROOT DISTRO PRE_COMMIT_INDEX
}

# Setup the script.
function setup() {
    setup_vars
}

# Cleanup the variables used by the script.
function cleanup_vars() {
    unset SCRIPT_DIR _LIB_PATH PROJECT_ROOT DISTRO PRE_COMMIT_PATHS PRE_COMMIT_INDEX
}

# Cleanup after the script.
# shellcheck disable=SC2329
function cleanup() {
    cleanup_vars
}

setup

# Run our cleanup routine on exit
trap cleanup EXIT

SCRIPT_DIR="$(get_script_dir)"

_LIB_PATH="$(readlink -f -- "${SCRIPT_DIR}/lib/")"

# shellcheck source=./lib/logging.sh
source "${_LIB_PATH}/logging.sh"
# shellcheck source=./lib/os.sh
source "${_LIB_PATH}/os.sh"
# shellcheck source=./lib/io.sh
source "${_LIB_PATH}/io.sh"

# The path to the project root directory
PROJECT_ROOT="$(readlink -f -- "${SCRIPT_DIR}/..")"

# Determine our distribution
DISTRO="$(get_distro)"

log_verbose "Determined OS distro to be \"${DISTRO}\""

if [[ -n "${CI}" && ! "$*" =~ \s*--force\s* ]]; then
    log_warning "Running in a CI environment, not setting up pre-commit!"
    exit 0
fi

# Locate pre-commit
if ! command -v pre-commit > /dev/null 2>&1; then
    log_warning "\"pre-commit\" is not installed, attempting to install via \"pipx\"!"
    if ! command -v pipx > /dev/null 2>&1; then
        log_warning "\"pipx\" is not installed, attempting to install!"
        case "${DISTRO}" in
            arch)
                PIPX_PACKAGE_NAME="python-pipx"
                ;;
            debian | ubuntu)
                PIPX_PACKAGE_NAME="pipx"
                ;;
            *)
                log_error "Unsupported distro \"${DISTRO}\"!"
                exit 1
                ;;
        esac
        if ! install_system_package "${PIPX_PACKAGE_NAME}"; then
            STATUS_CODE=$?
            log_error "Failed to install \"${PACKAGE_NAME}\"!"
            exit ${STATUS_CODE}
        else
            log_info "\"${PIPX_PACKAGE_NAME}\" was installed successfully!"
        fi
    fi
    pipx install pre-commit
    STATUS_CODE=$?
    if [[ ${STATUS_CODE} != 0 ]]; then
        log_verbose "\"pipx\" exited with code \"${STATUS_CODE}\"!"
        log_error "Failed to install \"pre-commit\"!"
        exit $STATUS_CODE
    fi
    log_info "\"pre-commit\" was installed successfully!"
    if ! command -v pre-commit > /dev/null 2>&1; then
        log_warning "Still cannot find \"pre-commit\", trying some well-known locations..."
        read -ra PRE_COMMIT_PATHS < <(find ~ -maxdepth 4 \( -type f -or -type l \) -executable -name pre-commit -printf '%p\n')
        read -ra PRE_COMMIT_PATHS < <(
            echo -n "${PRE_COMMIT_PATHS[*]} /usr/share/devtools/git.conf.d/template/hooks/pre-commit "
            find /usr/bin -maxdepth 4 \( -type f -or -type l \) -executable -name pre-commit -printf '%p\n'
        )
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
        PRE_COMMIT="${PRE_COMMIT_PATHS[${PRE_COMMIT_INDEX} - 1]}"
        log_verbose "Selected \"pre-commit\" executable \"${PRE_COMMIT}\""
        log_info "Adding \"$(dirname "${PRE_COMMIT}")\" to your PATH temporarily..."
        PATH="$(dirname "${PRE_COMMIT}"):${PATH}"
        log_info "\"$(dirname "${PRE_COMMIT}")\" is now on your PATH temporarily"
        log_warning "It's HIGHLY recommended to put this on your PATH permanently!"
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
pre-commit install --hook-type pre-commit --hook-type pre-push
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
