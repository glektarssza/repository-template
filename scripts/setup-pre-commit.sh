#!/usr/bin/env bash

# Forward declare some variables
declare -a PRE_COMMIT_PATHS;
declare SCRIPT_PATH PROJECT_ROOT DISTRO PRE_COMMIT_INDEX;

# Our cleanup function
# shellcheck disable=SC2329
function cleanup() {
    unset SCRIPT_PATH PROJECT_ROOT DISTRO PRE_COMMIT_PATHS PRE_COMMIT_INDEX;
}

# Run our cleanup routine on exit
trap cleanup EXIT;

# Log an error message to the standard error stream.
function log_error() {
  printf "\x1b[38;5;196m[ERROR]\x1b[0m %s\n" "$*" >&2;
}

# Log a warning message to the standard output stream.
function log_warning() {
  printf "\x1b[38;5;214m[WARN]\x1b[0m %s\n" "$*";
}

# Log an information message to the standard output stream.
function log_info() {
  printf "\x1b[38;5;111m[INFO]\x1b[0m %s\n" "$*";
}

# Log a verbose message to the standard output stream.
function log_verbose() {
  if [[ ! -n "${VERBOSE}" || ! "${VERBOSE,,}" =~ 1|true ]]; then
    return 0;
  fi
  printf "\x1b[38;5;171m[VERBOSE]\x1b[0m %s\n" "$*";
}

# Get the directory this script is running from.
function get_script_dir() {
    local SOURCE_PATH="${BASH_SOURCE[0]}";
    local SYMLINK_DIR;
    local SCRIPT_DIR;
    while [ -L "${SOURCE_PATH}" ]; do
        SYMLINK_DIR="$(cd -P "$(dirname "${SOURCE_PATH}")" > /dev/null 2>&1 && pwd)";
        SOURCE_PATH="$(readlink "${SOURCE_PATH}")";
        if [[ "${SOURCE_PATH}" != /* ]]; then
            SOURCE_PATH="${SYMLINK_DIR}/${SOURCE_PATH}";
        fi
    done
    SCRIPT_DIR="$(cd -P "$(dirname "${SOURCE_PATH}")" > /dev/null 2>&1 && pwd)";
    echo "${SCRIPT_DIR}";
}

# The path to the directory this script is living in
SCRIPT_PATH="$(get_script_dir)";

# The path to the project root directory
PROJECT_ROOT="$(readlink -f "${SCRIPT_PATH}/..")";

# Determine our distribution
DISTRO="$(cat /etc/os-release | grep '^ID' | awk -F'=' '{print $2;}')";

log_verbose "Determined OS distro to be \"${DISTRO}\"";

if [[ -n "${CI}" ]]; then
    log_warning "Running in a CI environment, not setting up pre-commit!";
    exit 0;
fi

# Locate pre-commit
PRE_COMMIT="$(which pre-commit 2> /dev/null)";
if [[ -z "${PRE_COMMIT}" ]]; then
    log_warning "\"pre-commit\" is not installed, attempting to install!";
    if ! which pipx > /dev/null 2>&1; then
        log_warning "\"pipx\" is not installed, attempting to install!";
        case "${DISTRO}" in
            arch)
                PACMAN="pacman";
                PACMAN_FLAGS=(-S --noconfirm --needed --asexplicit);
                PACKAGE_NAME="python-pipx";
            ;;
            debian|ubuntu)
                PACMAN=apt;
                PACMAN_FLAGS=(install --assume-yes --no-install-recommends);
                PACKAGE_NAME="pipx";
            ;;
        esac
        log_info "We're going to attempt to install \"pipx\", this will require admin permissions!";
        if [[ ! -x "${PACMAN}" ]]; then
            log_warning "Unable to execute \"${PACMAN}\" as we are, trying to elevate...";
            if which sudo; then
                log_verbose "Trying to elevate via \"sudo\"...";
                sudo --login eval "${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}";
                STATUS_CODE=$?;
            elif which su; then
                log_verbose "Trying to elevate via \"su\"...";
                su --login --command="${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}";
                STATUS_CODE=$?;
            else
                log_error "Failed to elevate!";
                exit 1;
            fi
        else
            exec "${PACMAN}" "${PACMAN_FLAGS[*]}" pipx;
            STATUS_CODE=$?;
        fi
        if [[ "${STATUS_CODE}" != "0" ]]; then
            log_verbose "\"${PACMAN}\" exited with code \"${STATUS_CODE}\"!";
            log_error "Failed to install \"pipx\"!";
            exit $STATUS_CODE;
        fi
        log_info "\"pipx\" was installed successfully!";
    fi
    pipx install pre-commit;
    STATUS_CODE=$?;
    if [[ "${STATUS_CODE}" != "0" ]]; then
        log_verbose "\"pipx\" exited with code \"${STATUS_CODE}\"!";
        log_error "Failed to install \"pre-commit\"!";
        exit $STATUS_CODE;
    fi
    log_info "\"pre-commit\" was installed successfully!";
    PRE_COMMIT="$(which pre-commit 2> /dev/null)";
    if [[ -z "${PRE_COMMIT}" ]]; then
        log_warning "Still cannot find \"pre-commit\", trying some well-known locations...";
        mapfile -t PRE_COMMIT_PATHS < <(find ~ -maxdepth 4 \( -type f -or -type l \) -name pre-commit -printf '%p\n');
        if [[ "${#PRE_COMMIT_PATHS[@]}" -le 0 ]]; then
            log_error "Failed to locate \"pre-commit\"!";
            exit 1;
        fi
        echo -e "Found the following \"pre-commit\" executables:\n$(echo "${PRE_COMMIT_PATHS[*]}" | awk -F' ' '{for(i=1;i<=NF;i+=1){print i": "$i;}}')"
        read -rep "Which one do you want to use? [index] " PRE_COMMIT_INDEX;
        while [[ ! "${PRE_COMMIT_INDEX}" =~ [[:digit:]]+ || "${PRE_COMMIT_INDEX}" -lt 0 || "${PRE_COMMIT_INDEX}" -gt "${#PRE_COMMIT_PATHS[@]}" ]]; do
            if [[ -z "${PRE_COMMIT_INDEX}" ]]; then
                PRE_COMMIT_INDEX="1";
                break;
            fi
            log_error "Value ${PRE_COMMIT_INDEX} is not valid, try again!";
            echo -e "Found the following \"pre-commit\" executables:\n$(echo "${PRE_COMMIT_PATHS[*]}" | awk -F' ' '{for(i=1;i<=NF;i+=1){print i": "$i;}}')"
            read -rep "Which one do you want to use? [index (default 1)] " PRE_COMMIT_INDEX;
        done
        log_verbose "\"pre-commit\" option index \"${PRE_COMMIT_INDEX}\" picked";
        PRE_COMMIT="${PRE_COMMIT_PATHS[(${PRE_COMMIT_INDEX}-1)]}";
        log_verbose "Selected \"pre-commit\" executable \"${PRE_COMMIT}\"";
    fi
fi

pushd "${PROJECT_ROOT}" > /dev/null 2>&1 || ( log_error "Failed to enter project root directory!" && exit 1; ) || exit 1;

log_info "Installing pre-commit hooks...";
"${PRE_COMMIT}" install --overwrite --hook-type pre-commit --hook-type pre-push;
STATUS_CODE=$?;
if [[ "${STATUS_CODE}" != "0" ]]; then
    log_verbose "\"pre-commit\" exited with code \"${STATUS_CODE}\"!";
    log_error "Failed to install pre-commit hooks!";
    exit $STATUS_CODE;
fi

popd > /dev/null 2>&1 || ( log_error "Failed to exit project root directory!" && exit 1; ) || exit 1;

# On success, exit
exit 0;
