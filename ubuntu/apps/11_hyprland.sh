#!/usr/bin/env bash
# Hyprland from the cppiber PPA (Ubuntu's own 0.53 predates the Lua config).
# GNOME stays installed and selectable at the GDM login screen.
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Hyprland Compositor"

add_ppa cppiber/hyprland
apt_install hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

# scratchd (scratchpads) — Rust rewrite of pyprland's scratchpads
ensure_mise
command -v cargo &>/dev/null || mise use --global rust@latest
log "Building scratchd..."
mise exec rust -- cargo install --locked --root "${HOME}/.local" --git https://github.com/darksworm/scratchd

# Deploy configs
log "Deploying Hyprland config..."
deploy_config "${CONF_DIR}/hypr/hyprland.lua" "${HOME}/.config/hypr/hyprland.lua"
deploy_config "${CONF_DIR}/scratchd/config.toml" "${HOME}/.config/scratchd/config.toml"

log "Hyprland installed — pick it from the session menu (gear icon) on the GDM login screen"
