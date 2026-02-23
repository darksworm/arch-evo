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
    log "Installing (yay): ${packages[*]}"
    yay -S --needed --noconfirm "${packages[@]}"
}

ensure_yay() {
    if ! command -v yay &>/dev/null; then
        log "Installing yay AUR helper..."
        local tmpdir
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "${tmpdir}/yay-bin"
        (cd "${tmpdir}/yay-bin" && makepkg -si --noconfirm)
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

    if [[ -d "${src}" ]]; then
        cp -r "${src}/." "${dest}/"
    else
        cp "${src}" "${dest}"
    fi
    log "Deployed: ${src} → ${dest}"
}

deploy_config_dir() {
    local src_dir="$1"
    local dest_dir="$2"
    mkdir -p "${dest_dir}"
    cp -r "${src_dir}/." "${dest_dir}/"
    log "Deployed directory: ${src_dir} → ${dest_dir}"
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
    systemctl --user enable "${service}"
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
