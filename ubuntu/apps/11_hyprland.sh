#!/usr/bin/env bash
# Hyprland from the cppiber PPA (Ubuntu's own 0.53 predates the Lua config).
# GNOME stays installed and selectable at the GDM login screen.
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Hyprland Compositor"

add_ppa cppiber/hyprland
apt_install hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# pyprland (scratchpads) — Python app, isolated via uv
ensure_mise
if ! command -v uv &>/dev/null; then
    mise use --global uv@latest
fi
uv tool install --upgrade pyprland

# Deploy configs
log "Deploying Hyprland config..."
deploy_config "${CONF_DIR}/hypr/hyprland.lua" "${HOME}/.config/hypr/hyprland.lua"
deploy_config "${CONF_DIR}/pypr/config.toml" "${HOME}/.config/pypr/config.toml"

log "Hyprland installed — pick it from the session menu (gear icon) on the GDM login screen"
