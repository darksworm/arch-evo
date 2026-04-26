#!/usr/bin/env bash
# Common applications
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Common Applications"

pac_install openssh gnupg btop bat acpi polkit-gnome libmtp gvfs-mtp yazi ffmpegthumbnailer poppler power-profiles-daemon

ensure_yay
yay_install zen-browser-bin spotify 1password 1password-cli vesktop-bin

# Deploy btop config
deploy_config_dir "${CONF_DIR}/btop" "${HOME}/.config/btop"

# Enable SSH agent
enable_user_service ssh-agent.service

# Power profile: auto-switch performance on AC, power-saver on battery
enable_service power-profiles-daemon.service
sudo cp "${CONF_DIR}/udev/99-power-profile.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules

log "Common applications installed"
