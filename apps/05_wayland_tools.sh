#!/usr/bin/env bash
# Wayland desktop tools: bar, launcher, notifications, lock, screenshots
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Wayland Tools"

pac_install \
    waybar fuzzel dunst hyprsunset \
    grim slurp wl-clipboard cliphist \
    brightnessctl \
    playerctl pamixer \
    xdg-desktop-portal-wlr \
    hyprlock hypridle

ensure_yay
yay_install awww-bin

# Deploy configs
deploy_config_dir "${CONF_DIR}/waybar" "${HOME}/.config/waybar"
deploy_config "${CONF_DIR}/dunst/dunstrc" "${HOME}/.config/dunst/dunstrc"
deploy_config "${CONF_DIR}/hypr/hyprlock.conf" "${HOME}/.config/hypr/hyprlock.conf"

# Hyprlock parallax assets (background + mountain foreground)
mkdir -p "${HOME}/.config/hypr/hyprlock"
cp -f "${REPO_DIR}/static/hyprlock/wall.jpg" "${HOME}/.config/hypr/hyprlock/wall.jpg"
cp -f "${REPO_DIR}/static/hyprlock/fg.png" "${HOME}/.config/hypr/hyprlock/fg.png"
deploy_config "${CONF_DIR}/hypr/hypridle.conf" "${HOME}/.config/hypr/hypridle.conf"
deploy_config "${CONF_DIR}/hypr/hyprsunset.conf" "${HOME}/.config/hypr/hyprsunset.conf"
deploy_config "${CONF_DIR}/fuzzel/fuzzel.ini" "${HOME}/.config/fuzzel/fuzzel.ini"

log "Wayland tools installed and configured"
