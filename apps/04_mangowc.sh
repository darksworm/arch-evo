#!/usr/bin/env bash
# MangoWC - Lightweight Wayland compositor built on dwl
# https://github.com/DreamMaoMao/mangowc
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "MangoWC Compositor"

yay_install mangowc-git

# Deploy config
log "Deploying MangoWC config..."
deploy_config "${CONF_DIR}/mango/config.conf" "${HOME}/.config/mango/config.conf"

# Create Wayland session desktop file
log "Creating wayland session entry..."
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/mango.desktop > /dev/null <<EOF
[Desktop Entry]
Name=MangoWC
Comment=Lightweight Wayland Compositor
Exec=mango
Type=Application
DesktopNames=mango
EOF

log "MangoWC installed"
