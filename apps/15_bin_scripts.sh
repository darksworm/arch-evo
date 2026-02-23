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
