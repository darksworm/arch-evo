#!/usr/bin/env bash
# Hyprland - Dynamic tiling Wayland compositor
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Hyprland Compositor"

pac_install hyprland

ensure_yay
yay_install pyprland

# Deploy configs
log "Deploying Hyprland config..."
deploy_config "${CONF_DIR}/hypr/hyprland.lua" "${HOME}/.config/hypr/hyprland.lua"
deploy_config "${CONF_DIR}/pypr/config.toml" "${HOME}/.config/pypr/config.toml"

log "Hyprland installed"
