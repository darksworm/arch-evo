#!/usr/bin/env bash
# Logging, error handling, and package management utilities

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

die() {
    error "$@"
    exit 1
}

section() {
    echo ""
    echo -e "${BLUE}=== $* ===${NC}"
    echo ""
}

pac_install() {
    local packages=("$@")
    log "Installing (pacman): ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

yay_install() {
    local packages=("$@")
    local builddir="/tmp/yay-build"
    mkdir -p "${builddir}"
    chown "${USERNAME}:${USERNAME}" "${builddir}"
    log "Installing (yay): ${packages[*]}"
    sudo -u "${USERNAME}" yay --builddir "${builddir}" -S --needed --noconfirm --cleanmenu=false --diffmenu=false --removemake=false "${packages[@]}"
}

ensure_yay() {
    if ! command -v yay &>/dev/null; then
        log "Installing yay AUR helper..."
        local tmpdir
        tmpdir=$(mktemp -d)
        chmod 777 "${tmpdir}"
        sudo -u "${USERNAME}" git clone https://aur.archlinux.org/yay-bin.git "${tmpdir}/yay-bin"
        (cd "${tmpdir}/yay-bin" && sudo -u "${USERNAME}" makepkg -si --noconfirm)
        rm -rf "${tmpdir}"
    fi
}

deploy_config() {
    local src="$1"
    local dest="$2"

    if [[ ! -f "${src}" && ! -d "${src}" ]]; then
        warn "Config source not found: ${src}"
        return 1
    fi

    local dest_dir
    dest_dir=$(dirname "${dest}")
    mkdir -p "${dest_dir}"

    ln -sfn "${src}" "${dest}"
    log "Linked: ${src} → ${dest}"
}

deploy_config_dir() {
    local src_dir="$1"
    local dest_dir="$2"
    local parent_dir
    parent_dir=$(dirname "${dest_dir}")
    mkdir -p "${parent_dir}"
    ln -sfn "${src_dir}" "${dest_dir}"
    log "Linked directory: ${src_dir} → ${dest_dir}"
}

enable_service() {
    local service="$1"
    if is_docker; then
        log "Docker mode: skipping enable ${service}"
        return 0
    fi
    log "Enabling service: ${service}"
    sudo systemctl enable "${service}"
}

enable_user_service() {
    local service="$1"
    if is_docker; then
        log "Docker mode: skipping user service enable ${service}"
        return 0
    fi
    log "Enabling user service: ${service}"
    # In chroot or without a user session, symlink manually
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] || [[ "$(id -u)" -eq 0 ]]; then
        local user_home
        user_home=$(eval echo "~${USERNAME}")
        local wants_dir="${user_home}/.config/systemd/user/default.target.wants"
        mkdir -p "${wants_dir}"
        chown -R "${USERNAME}:${USERNAME}" "${user_home}/.config/systemd"
        ln -sfn "/usr/lib/systemd/user/${service}" "${wants_dir}/${service}"
    else
        systemctl --user enable "${service}"
    fi
}

mark_completed() {
    local script_name="$1"
    mkdir -p "${COMPLETED_DIR}"
    touch "${COMPLETED_DIR}/${script_name}"
}

is_completed() {
    local script_name="$1"
    [[ -f "${COMPLETED_DIR}/${script_name}" ]]
}

run_as_user() {
    local user="$1"
    shift
    sudo -u "${user}" bash -c "$*"
}
