#!/usr/bin/env bash
# GTK theme, icons, cursor, fonts
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Theme & Appearance"

pac_install ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

ensure_yay
yay_install adw-gtk3 papirus-icon-theme bibata-cursor-theme-bin

# GTK 3 settings
deploy_config "${CONF_DIR}/gtk-3.0/settings.ini" "${HOME}/.config/gtk-3.0/settings.ini"

# GTK 4 settings
deploy_config "${CONF_DIR}/gtk-4.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"

# Deploy wallpapers
mkdir -p "${HOME}/.local/share/wallpapers"
if [[ -d "${REPO_DIR}/static/wallpapers" ]] && ls "${REPO_DIR}/static/wallpapers/"* &>/dev/null; then
    cp "${REPO_DIR}/static/wallpapers/"* "${HOME}/.local/share/wallpapers/"
fi

log "Theme and appearance configured"
