#!/usr/bin/env bash
# Keyboard remapping via keyd: Caps Lock → Esc (tap) / Hyper (hold)
# Hyper = Ctrl+Alt+Super, used for app scratchpad binds in Hyprland
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Keyboard Remapping"

pac_install keyd

sudo mkdir -p /etc/keyd
sudo ln -sfn "${CONF_DIR}/keyd/default.conf" "/etc/keyd/default.conf"

enable_service keyd.service

log "Keyboard remapping (keyd) installed: tap=Esc, hold=Hyper"
