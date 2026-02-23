#!/usr/bin/env bash
# DWL - Dynamic Window Manager for Wayland (compiled from source)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "DWL Compositor"

pac_install wayland-protocols wlroots libinput libxkbcommon pixman pkg-config

DWL_SRC="/opt/dwl"
DWL_BRANCH="main"

if [[ -d "${DWL_SRC}" ]]; then
    log "DWL source already exists at ${DWL_SRC}, pulling latest..."
    (cd "${DWL_SRC}" && sudo git pull)
else
    log "Cloning DWL..."
    sudo git clone https://codeberg.org/dwl/dwl.git "${DWL_SRC}"
fi

# Copy custom config.h
log "Deploying custom config.h..."
sudo cp "${CONF_DIR}/dwl/config.h" "${DWL_SRC}/config.h"

# Build and install
log "Building DWL..."
(cd "${DWL_SRC}" && sudo make clean && sudo make && sudo make install)

# Create Wayland session desktop file
log "Creating wayland session entry..."
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/dwl.desktop > /dev/null <<EOF
[Desktop Entry]
Name=DWL
Comment=Dynamic Wayland Compositor
Exec=dwl -s "sh ~/.local/bin/autostart.sh"
Type=Application
DesktopNames=dwl
EOF

log "DWL installed"
