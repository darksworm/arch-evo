#!/usr/bin/env bash
# GTK theme, icons, cursor, fonts
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Theme & Appearance"

pac_install ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji

ensure_yay
yay_install adw-gtk3 papirus-icon-theme bibata-cursor-theme-bin matuwall hyprdynamicmonitors-bin

# GTK 3 settings
deploy_config "${CONF_DIR}/gtk-3.0/settings.ini" "${HOME}/.config/gtk-3.0/settings.ini"

# GTK 4 settings
deploy_config "${CONF_DIR}/gtk-4.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"

# Deploy wallpapers
if [[ -d "${REPO_DIR}/static/wallpapers" ]]; then
    ln -sfn "${REPO_DIR}/static/wallpapers" "${HOME}/.local/share/wallpapers"
fi

# Matuwall config (wallpaper picker)
deploy_config "${CONF_DIR}/matuwall/config.json" "${HOME}/.config/matuwall/config.json"

# libadwaita / GNOME apps read color-scheme from dconf, not the GTK ini.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'

log "Theme and appearance configured"
