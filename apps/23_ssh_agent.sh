#!/usr/bin/env bash
# SSH agent setup: systemd ssh-agent.service + pass-backed askpass.
# Manual setup steps (passphrases into pass) are documented in
# notes/secrets.md.
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "SSH Agent"

# Pinentry (gpg-agent calls it for `pass`).
# `gcr` is the gnome-keyring v3 lib; pinentry-gnome3 still links against
# libgcr-base-3.so.1 even though gcr-4 is the current default — without
# `gcr` installed alongside, pinentry-gnome3 fails with "No pinentry".
pac_install pinentry gcr

enable_user_service ssh-agent.service

# Deploy gpg-agent.conf (cache TTL + dark-themed pinentry-gnome3)
mkdir -p "${HOME}/.gnupg"
chmod 700 "${HOME}/.gnupg"
deploy_config "${CONF_DIR}/gnupg/gpg-agent.conf" "${HOME}/.gnupg/gpg-agent.conf"
gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true

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
