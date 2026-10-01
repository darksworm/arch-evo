#!/usr/bin/env bash
# SSH: key + AddKeysToAgent. The agent is GNOME's gcr-ssh-agent (systemd
# user socket at $XDG_RUNTIME_DIR/gcr/ssh), which also works under Hyprland.
# The Arch setup's pass-backed askpass is not ported yet (notes/secrets.md).
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "SSH"

apt_install openssh-client gcr

systemctl --user enable --now gcr-ssh-agent.socket

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Same key type/name as the Arch install; .gitconfig signs commits with it
if [[ ! -f "${HOME}/.ssh/id_ecdsa" ]]; then
    log "Generating SSH key (you'll be asked for a passphrase)..."
    ssh-keygen -t ecdsa -b 521 -f "${HOME}/.ssh/id_ecdsa"
else
    log "SSH key already exists: ~/.ssh/id_ecdsa"
fi

# Drop in ~/.ssh/config with AddKeysToAgent yes — merge non-destructively
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

log "SSH configured. Public key: ~/.ssh/id_ecdsa.pub"
