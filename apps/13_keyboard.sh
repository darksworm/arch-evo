#!/usr/bin/env bash
# Keyboard remapping via keyd: Caps Lock → Esc (tap) / Hyper (hold)
# Hyper = Ctrl+Alt+Super, used for app scratchpad binds in Hyprland
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Keyboard Remapping"

pac_install keyd
pac_install wtype # bin/caps-toggle uses it to clear a stuck caps lock

sudo mkdir -p /etc/keyd
sudo ln -sfn "${CONF_DIR}/keyd/default.conf" "/etc/keyd/default.conf"

enable_service keyd.service

# keyd group allows runtime rebinds (bin/caps-toggle) without sudo
sudo usermod -aG keyd "${USERNAME}"

log "Keyboard remapping (keyd) installed: tap=Esc, hold=Hyper"
