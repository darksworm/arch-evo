#!/usr/bin/env bash
# Deploy utility scripts to ~/.local/bin
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Utility Scripts"

mkdir -p "${HOME}/.local/bin"

# Symlink all bin scripts
for script in "${BIN_DIR}"/*; do
    [[ -f "${script}" ]] || continue
    dest="${HOME}/.local/bin/$(basename "${script}")"
    ln -sf "${script}" "${dest}"
    log "Linked: $(basename "${script}")"
done

log "Utility scripts deployed to ~/.local/bin"

# fanmode-auto: load-adaptive power profile service.
# systemd refuses to enable symlinked unit files, so copy instead of deploy_config.
install -Dm644 "${CONF_DIR}/systemd/fanmode-auto.service" "${HOME}/.config/systemd/user/fanmode-auto.service"
mkdir -p "${HOME}/.config/systemd/user/default.target.wants"
ln -sfn "../fanmode-auto.service" "${HOME}/.config/systemd/user/default.target.wants/fanmode-auto.service"
log "Enabled fanmode-auto.service"
