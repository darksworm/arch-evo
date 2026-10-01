#!/usr/bin/env bash
# Ubuntu package helpers: apt, PPAs, third-party apt repos, GitHub releases

APT_UPDATED=0

apt_update() {
    log "Updating apt package lists..."
    sudo apt-get update -qq
    APT_UPDATED=1
}

apt_install() {
    local packages=("$@")
    [[ ${APT_UPDATED} -eq 1 ]] || apt_update
    log "Installing (apt): ${packages[*]}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
}

# add_ppa owner/name
add_ppa() {
    local ppa="$1"
    if grep -rqs "${ppa}" /etc/apt/sources.list.d/; then
        log "PPA already added: ${ppa}"
        return 0
    fi
    log "Adding PPA: ${ppa}"
    sudo add-apt-repository -y "ppa:${ppa}"
    APT_UPDATED=0
}

# add_apt_repo NAME KEY_URL "deb [signed-by=@KEYRING@] URL SUITE COMPONENTS"
# @KEYRING@ in the source line is replaced with the keyring path.
add_apt_repo() {
    local name="$1" key_url="$2" line="$3"
    local keyring="/etc/apt/keyrings/${name}.gpg"
    local list="/etc/apt/sources.list.d/${name}.list"

    sudo install -d -m 0755 /etc/apt/keyrings
    log "Fetching apt key for ${name}..."
    curl -fsSL "${key_url}" | gpg --dearmor | sudo tee "${keyring}" >/dev/null
    sudo chmod 0644 "${keyring}"
    echo "${line//@KEYRING@/${keyring}}" | sudo tee "${list}" >/dev/null
    APT_UPDATED=0
}

# gh_latest_tag owner/repo → prints the latest release tag (e.g. v1.2.3)
gh_latest_tag() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r '.tag_name'
}

# install_deb_url URL — download a .deb and install it with dependencies
install_deb_url() {
    local url="$1"
    local tmp
    tmp=$(mktemp -d)
    log "Downloading ${url##*/}..."
    curl -fsSL -o "${tmp}/pkg.deb" "${url}"
    # apt reads local .debs as the _apt user; mktemp's 0700 dir blocks it
    chmod 755 "${tmp}"
    chmod 644 "${tmp}/pkg.deb"
    apt_install "${tmp}/pkg.deb"
    rm -rf "${tmp}"
}

# install_tarball URL DEST_DIR — extract a release tarball into DEST_DIR,
# replacing any previous version.
install_tarball() {
    local url="$1" dest="$2"
    local tmp
    tmp=$(mktemp -d)
    log "Downloading ${url##*/}..."
    curl -fsSL -o "${tmp}/archive" "${url}"
    rm -rf "${dest}"
    mkdir -p "${dest}"
    tar -xf "${tmp}/archive" -C "${dest}"
    rm -rf "${tmp}"
}

# link_bin SRC [NAME] — symlink an executable into ~/.local/bin
link_bin() {
    local src="$1" name="${2:-$(basename "$1")}"
    mkdir -p "${LOCAL_BIN}"
    ln -sfn "${src}" "${LOCAL_BIN}/${name}"
    log "Linked: ${LOCAL_BIN}/${name} → ${src}"
}

ensure_mise() {
    if ! command -v mise &>/dev/null && [[ ! -x "${LOCAL_BIN}/mise" ]]; then
        log "Installing mise..."
        curl -fsSL https://mise.run | sh
    fi
    export PATH="${LOCAL_BIN}:${HOME}/.local/share/mise/shims:${PATH}"
}
