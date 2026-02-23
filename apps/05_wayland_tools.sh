#!/usr/bin/env bash
# Wayland desktop tools: bar, launcher, notifications, lock, screenshots
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Wayland Tools"

pac_install \
    waybar bemenu bemenu-wayland \
    mako swaylock swayidle swaybg \
    grim slurp wl-clipboard wob \
    gammastep brightnessctl \
    playerctl pamixer \
    xdg-desktop-portal-wlr

# Deploy configs
deploy_config_dir "${CONF_DIR}/waybar" "${HOME}/.config/waybar"
deploy_config "${CONF_DIR}/mako/config" "${HOME}/.config/mako/config"
deploy_config "${CONF_DIR}/swaylock/config" "${HOME}/.config/swaylock/config"

log "Wayland tools installed and configured"
