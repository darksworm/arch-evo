#!/usr/bin/env bash
# Bluetooth support
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Bluetooth"

pac_install bluez bluez-utils blueman

enable_service bluetooth.service

# blueman's AutoConnect races bluetoothd's own reconnect and drops the device
gsettings set org.blueman.general plugin-list "['!AutoConnect']"

log "Bluetooth installed and enabled"
