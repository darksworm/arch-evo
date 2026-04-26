#!/usr/bin/env bash
# SSH agent setup: systemd ssh-agent.service + pass-backed askpass.
# Manual setup steps (passphrases into pass) are documented in
# notes/secrets.md.
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "SSH Agent"

# Pinentry that works in graphical sessions (gpg-agent calls it for `pass`)
pac_install pinentry

enable_user_service ssh-agent.service

# Drop in ~/.ssh/config with AddKeysToAgent yes — merge non-destructively
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

SSH_CONFIG="${HOME}/.ssh/config"
MARKER="# arch-evo: AddKeysToAgent"

if [[ ! -f "${SSH_CONFIG}" ]]; then
    {
        echo "${MARKER}"
        cat "${CONF_DIR}/ssh/config"
    } > "${SSH_CONFIG}"
    chmod 600 "${SSH_CONFIG}"
    log "Created ${SSH_CONFIG}"
elif ! grep -q "${MARKER}" "${SSH_CONFIG}"; then
    {
        echo ""
        echo "${MARKER}"
        cat "${CONF_DIR}/ssh/config"
    } >> "${SSH_CONFIG}"
    log "Appended AddKeysToAgent block to ${SSH_CONFIG}"
else
    log "${SSH_CONFIG} already configured"
fi

log "Done. See notes/secrets.md to populate pass with key passphrases."
