#!/usr/bin/env bash
# Common applications
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Common Applications"

pac_install openssh gnupg btop acpi polkit-gnome discord

ensure_yay
yay_install zen-browser-bin spotify 1password

# Deploy btop config
deploy_config_dir "${CONF_DIR}/btop" "${HOME}/.config/btop"

# Enable SSH agent
enable_user_service ssh-agent.service

log "Common applications installed"
