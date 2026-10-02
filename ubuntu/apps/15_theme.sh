#!/usr/bin/env bash
# GTK theme, icons, cursor, fonts
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Theme & Appearance"

apt_install fonts-noto fonts-noto-color-emoji papirus-icon-theme bibata-cursor-theme fontconfig

# JetBrains Mono Nerd Font — not packaged for Ubuntu
FONT_DIR="${XDG_DATA_HOME}/fonts/JetBrainsMonoNerd"
if [[ ! -d "${FONT_DIR}" ]]; then
    install_tarball \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
        "${FONT_DIR}"
    fc-cache -f "${FONT_DIR}"
fi

# adw-gtk3 — libadwaita look for GTK3 apps, from upstream release
ADW_TAG=$(gh_latest_tag lassekongo83/adw-gtk3)
mkdir -p "${XDG_DATA_HOME}/themes"
tmp=$(mktemp -d)
curl -fsSL -o "${tmp}/adw.tar.xz" \
    "https://github.com/lassekongo83/adw-gtk3/releases/download/${ADW_TAG}/adw-gtk3${ADW_TAG}.tar.xz"
rm -rf "${XDG_DATA_HOME}/themes/adw-gtk3" "${XDG_DATA_HOME}/themes/adw-gtk3-dark"
tar -xf "${tmp}/adw.tar.xz" -C "${XDG_DATA_HOME}/themes"
rm -rf "${tmp}"
log "Installed adw-gtk3 ${ADW_TAG}"

# GTK 3 settings
deploy_config "${CONF_DIR}/gtk-3.0/settings.ini" "${HOME}/.config/gtk-3.0/settings.ini"

# GTK 4 settings
deploy_config "${CONF_DIR}/gtk-4.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"

# Deploy wallpapers
if [[ -d "${REPO_DIR}/static/wallpapers" ]]; then
    mkdir -p "${XDG_DATA_HOME}"
    ln -sfn "${REPO_DIR}/static/wallpapers" "${XDG_DATA_HOME}/wallpapers"
fi

# libadwaita / GNOME apps read these from dconf, not the GTK ini.
# Applies to the GNOME session too.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'

# Snaps (chromium, firefox, ...) can't see ~/.local/share/themes and fall back
# to light Adwaita; a theme snap is shared with them via gtk-common-themes.
if command -v snap &>/dev/null; then
    sudo snap install gtk-theme-adw-gtk3
fi

log "Theme and appearance configured"
