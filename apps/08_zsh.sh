#!/usr/bin/env bash
# Zsh shell setup with starship, zoxide, fzf, direnv
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Zsh Shell"

pac_install zsh starship zoxide fzf direnv zsh-autosuggestions

ensure_yay
yay_install zsh-vi-mode zsh-fast-syntax-highlighting zsh-fzf-history-search-git

# Deploy configs
deploy_config "${CONF_DIR}/zsh/zshrc" "${HOME}/.zshrc"
deploy_config "${CONF_DIR}/zsh/zshenv" "${HOME}/.zshenv"
deploy_config "${CONF_DIR}/zsh/zprofile" "${HOME}/.zprofile"
mkdir -p "${HOME}/.config/zsh/plugins"
deploy_config "${CONF_DIR}/zsh/plugins/base.zsh" "${HOME}/.config/zsh/plugins/base.zsh"
deploy_config "${CONF_DIR}/zsh/plugins/dev.zsh" "${HOME}/.config/zsh/plugins/dev.zsh"
deploy_config "${CONF_DIR}/starship.toml" "${HOME}/.config/starship.toml"

# Set zsh as default shell
if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    log "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

log "Zsh installed and configured"
