#!/usr/bin/env bash
# Neovim (upstream release — apt lags behind LazyVim's minimum) with LazyVim
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Neovim (LazyVim)"

# LazyVim runtime deps; ripgrep/fd/fzf power the pickers
apt_install git ripgrep fd-find fzf build-essential
link_bin /usr/bin/fdfind fd

# Installed system-wide so /usr/local/bin/nvim works for sudoedit and git
NVIM_PREFIX=/opt/nvim-linux-x86_64
tmp=$(mktemp -d)
log "Downloading latest neovim release..."
curl -fsSL -o "${tmp}/nvim.tar.gz" \
    https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf "${NVIM_PREFIX}"
sudo tar -C /opt -xzf "${tmp}/nvim.tar.gz"
sudo ln -sfn "${NVIM_PREFIX}/bin/nvim" /usr/local/bin/nvim
rm -rf "${tmp}"
log "Installed $(/usr/local/bin/nvim --version | head -1)"

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

# Deploy lazyvim.json (extras configuration)
deploy_config "${CONF_DIR}/nvim/lazyvim.json" "${NVIM_DIR}/lazyvim.json"

# Run headless plugin install
log "Installing neovim plugins (headless)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Headless plugin install may need manual run"

log "Neovim (LazyVim) installed"
