#!/usr/bin/env bash
# Hyprland - Dynamic tiling Wayland compositor
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Hyprland Compositor"

pac_install hyprland

# Deploy config
log "Deploying Hyprland config..."
deploy_config "${CONF_DIR}/hypr/hyprland.conf" "${HOME}/.config/hypr/hyprland.conf"

log "Hyprland installed"
