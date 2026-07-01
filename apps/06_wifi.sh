#!/usr/bin/env bash
# WiFi & networking (NetworkManager already installed in chroot)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Networking"

# iPhone USB tethering
pac_install usbmuxd libimobiledevice
enable_service usbmuxd.service

enable_service NetworkManager.service

# Office attendance log via NM dispatcher
DISPATCHER_DEST="/etc/NetworkManager/dispatcher.d/office-log"
sudo cp "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/conf/nm-dispatcher/office-log" "$DISPATCHER_DEST"
sudo chmod 755 "$DISPATCHER_DEST"
log "Office attendance dispatcher installed → $DISPATCHER_DEST"

log "NetworkManager and iPhone tethering enabled"
