#!/usr/bin/env bash
# Bluetooth support
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Bluetooth"

pac_install bluez bluez-utils blueman

enable_service bluetooth.service

log "Bluetooth installed and enabled"
