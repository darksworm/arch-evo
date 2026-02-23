#!/usr/bin/env bash
# Keyboard remapping: Caps Lock → Escape (tap) / Ctrl (hold)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Keyboard Remapping"

pac_install interception-tools interception-caps2esc

# Deploy udevmon config (system directory, needs sudo)
sudo mkdir -p /etc/interception
sudo ln -sfn "${CONF_DIR}/interception/udevmon.yaml" "/etc/interception/udevmon.yaml"

enable_service udevmon.service

log "Keyboard remapping (caps2esc) installed and enabled"
