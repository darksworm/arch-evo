#!/usr/bin/env bash
# Wayland desktop tools: bar, launcher, notifications, lock, screenshots
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Wayland Tools"

pac_install \
    waybar fuzzel dunst wlsunset \
    grim slurp wl-clipboard \
    brightnessctl \
    playerctl pamixer \
    xdg-desktop-portal-wlr \
    hyprlock hypridle swww

# Deploy configs
deploy_config_dir "${CONF_DIR}/waybar" "${HOME}/.config/waybar"
deploy_config "${CONF_DIR}/dunst/dunstrc" "${HOME}/.config/dunst/dunstrc"
deploy_config "${CONF_DIR}/hypr/hyprlock.conf" "${HOME}/.config/hypr/hyprlock.conf"
deploy_config "${CONF_DIR}/hypr/hypridle.conf" "${HOME}/.config/hypr/hypridle.conf"
deploy_config "${CONF_DIR}/fuzzel/fuzzel.ini" "${HOME}/.config/fuzzel/fuzzel.ini"

log "Wayland tools installed and configured"
