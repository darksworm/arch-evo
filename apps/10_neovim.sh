#!/usr/bin/env bash
# Neovim with LazyVim distribution
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Neovim (LazyVim)"

pac_install neovim

NVIM_DIR="${HOME}/.config/nvim"

if [[ -d "${NVIM_DIR}" ]]; then
    warn "Neovim config already exists at ${NVIM_DIR}, skipping clone"
else
    log "Cloning LazyVim starter..."
    git clone https://github.com/LazyVim/starter "${NVIM_DIR}"
    rm -rf "${NVIM_DIR}/.git"
fi

# Deploy customizations overlay
for f in "${CONF_DIR}"/nvim/lua/plugins/*.lua; do
    [[ -f "${f}" ]] || continue
    deploy_config "${f}" "${NVIM_DIR}/lua/plugins/$(basename "${f}")"
done

for f in "${CONF_DIR}"/nvim/lua/config/*.lua; do
    [[ -f "${f}" ]] || continue
    deploy_config "${f}" "${NVIM_DIR}/lua/config/$(basename "${f}")"
done

# Run headless plugin install
log "Installing neovim plugins (headless)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Headless plugin install may need manual run"

log "Neovim (LazyVim) installed"
