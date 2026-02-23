#!/usr/bin/env bash
# WiFi (NetworkManager already installed in chroot)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "WiFi"

enable_service NetworkManager.service

log "NetworkManager enabled"
