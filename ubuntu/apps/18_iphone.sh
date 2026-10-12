#!/usr/bin/env bash
# iPhone USB tethering (NetworkManager picks up the interface automatically)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "iPhone Tethering"

apt_install usbmuxd libimobiledevice-utils

log "iPhone tethering ready — plug in, trust the computer, enable Personal Hotspot"
