#!/usr/bin/env bash
# Wayland base packages
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Wayland Base"

pac_install wayland wayland-protocols libinput xorg-xwayland

log "Wayland base packages installed"
