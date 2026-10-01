#!/usr/bin/env bash
# Keyboard remapping via keyd: Caps Lock → Esc (tap) / Hyper (hold)
# Hyper = Ctrl+Alt+Super, used for app scratchpad binds in Hyprland
# (no F1-F3 media remap on Ubuntu)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Keyboard Remapping"

apt_install keyd
apt_install wtype # bin/caps-toggle uses it to clear a stuck caps lock

# Debian ships the binary as keyd.rvaiya; bin/caps-toggle calls `keyd`
sudo ln -sfn /usr/bin/keyd.rvaiya /usr/local/bin/keyd

sudo mkdir -p /etc/keyd
# Copy of the shared config minus the F1/F2/F3 → mute/vol remap: that was a
# workaround for the T14s firmware and would eat real F-keys here.
sudo rm -f /etc/keyd/default.conf
sed -e '/^# Firmware emits raw F1/,/^f3 = /d' "${CONF_DIR}/keyd/default.conf" \
    | sudo tee /etc/keyd/default.conf >/dev/null

enable_service keyd.service

# keyd group allows runtime rebinds (bin/caps-toggle) without sudo
getent group keyd >/dev/null || sudo groupadd keyd
sudo usermod -aG keyd "${USERNAME}"

log "Keyboard remapping (keyd) installed: tap=Esc, hold=Hyper"
