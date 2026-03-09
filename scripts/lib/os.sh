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

if [[ -n "${_LIB_OS_GUARD+x}" ]]; then
    return 0
fi
declare _LIB_OS_GUARD

# shellcheck source=./logging.sh
source "${_LIB_PATH}/logging.sh"

# Get the Linux distro the script is currently being run on.
function get_distro() {
    cat /etc/os-release | grep '^ID' | awk -F'=' '{print $2;}' 2> /dev/null
    return $?
}

function install_system_package() {
    local -a PACMAN_FLAGS
    local PACMAN PACKAGE_NAME DISTRO STATUS_CODE
    DISTRO="$(get_distro)"
    PACKAGE_NAME="$1"
    shift
    if [[ -z "${PACKAGE_NAME}" ]]; then
        log_error "install_system_package: A package name is required!"
    fi
    case "${DISTRO}" in
        arch)
            PACMAN="pacman"
            PACMAN_FLAGS=(-S --noconfirm --needed --asexplicit)
            ;;
        debian | ubuntu)
            PACMAN="apt"
            PACMAN_FLAGS=(install --assume-yes --no-install-recommends)
            ;;
        *)
            log_error "install_system_package: Unsupported distro \"${DISTRO}\"!"
            ;;
    esac
    read -ra PACMAN_FLAGS > /dev/null 2>&1 < <(echo "${PACMAN_FLAGS[*]} $*")
    log_info "We're going to attempt to install \"${PACKAGE_NAME}\", this will require admin permissions!"
    if [[ ! -x "${PACMAN}" ]]; then
        log_warning "Unable to execute \"${PACMAN}\" as we are, trying to elevate..."
        if command -v sudo >&/dev/null; then
            if ! prompt_to_continue "We're about to run 'sudo \"${SHELL}\" -i -c \"${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}\"'." "n"; then
                log_error "Not authorized, aborting install!"
                STATUS_CODE=1
            else
                log_verbose "Trying to elevate via \"sudo\"..."
                sudo --login eval "${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}"
                STATUS_CODE=$?
            fi
        elif command -v su >&/dev/null; then
            if ! prompt_to_continue "We're about to run 'su --login --command=\n\"${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}\"'." "n"; then
                log_error "Not authorized, aborting install!"
                STATUS_CODE=1
            else
                log_verbose "Trying to elevate via \"su\"..."
                su --login --command="${PACMAN} ${PACMAN_FLAGS[*]} ${PACKAGE_NAME}"
                STATUS_CODE=$?
            fi

        else
            log_error "Failed to elevate: unable to find compatible suid program!"
            STATUS_CODE=1
        fi
    else
        exec "${PACMAN}" "${PACMAN_FLAGS[*]}" pipx
        STATUS_CODE=$?
    fi
    if [[ "${STATUS_CODE}" != "0" ]]; then
        log_verbose "\"${PACMAN}\" exited with code \"${STATUS_CODE}\"!"
    fi
    return ${STATUS_CODE}
}
