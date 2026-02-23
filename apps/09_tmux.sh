#!/usr/bin/env bash
# Tmux with TPM plugin manager
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Tmux"

pac_install tmux

# Clone TPM
TPM_DIR="${HOME}/.config/tmux/plugins/tpm"
if [[ ! -d "${TPM_DIR}" ]]; then
    log "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
fi

# Deploy config
deploy_config "${CONF_DIR}/tmux.conf" "${HOME}/.config/tmux/tmux.conf"

# Install plugins
log "Installing tmux plugins..."
"${TPM_DIR}/bin/install_plugins" || warn "TPM plugin install failed (run prefix+I in tmux)"

log "Tmux installed and configured"
