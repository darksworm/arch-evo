#!/usr/bin/env bash
# WiFi & networking (NetworkManager already installed in chroot)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Networking"

# iPhone USB tethering
pac_install usbmuxd libimobiledevice
enable_service usbmuxd.service

enable_service NetworkManager.service

log "NetworkManager and iPhone tethering enabled"
