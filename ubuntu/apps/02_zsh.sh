#!/usr/bin/env bash
# Zsh shell setup with starship, zoxide, fzf, direnv
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Zsh Shell"

apt_install zsh starship zoxide fzf direnv zsh-autosuggestions

# Not packaged for Ubuntu — cloned into the path the zsh configs search
ZSH_PLUGIN_DIR="${XDG_DATA_HOME}/zsh/plugins"
mkdir -p "${ZSH_PLUGIN_DIR}"
for repo in jeffreytse/zsh-vi-mode zdharma-continuum/fast-syntax-highlighting; do
    dest="${ZSH_PLUGIN_DIR}/${repo##*/}"
    if [[ -d "${dest}/.git" ]]; then
        git -C "${dest}" pull --ff-only -q || warn "Could not update ${repo}"
    else
        log "Cloning ${repo}..."
        git clone --depth 1 "https://github.com/${repo}" "${dest}"
    fi
done

# Deploy configs
deploy_config "${CONF_DIR}/zsh/zshrc" "${HOME}/.zshrc"
deploy_config "${CONF_DIR}/zsh/zshenv" "${HOME}/.zshenv"
deploy_config "${CONF_DIR}/zsh/zprofile" "${HOME}/.zprofile"
mkdir -p "${HOME}/.config/zsh/plugins"
deploy_config "${CONF_DIR}/zsh/plugins/base.zsh" "${HOME}/.config/zsh/plugins/base.zsh"
deploy_config "${CONF_DIR}/zsh/plugins/dev.zsh" "${HOME}/.config/zsh/plugins/dev.zsh"
deploy_config "${CONF_DIR}/starship.toml" "${HOME}/.config/starship.toml"

# Set zsh as default shell
if [[ "$(getent passwd "${USER}" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    log "Setting zsh as default shell..."
    chsh -s "$(command -v zsh)"
fi

log "Zsh installed and configured (log out and back in to switch shell)"
