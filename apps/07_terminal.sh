#!/usr/bin/env bash
# Foot terminal emulator (Wayland-native)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Foot Terminal"

pac_install foot

deploy_config "${CONF_DIR}/foot/foot.ini" "${HOME}/.config/foot/foot.ini"

log "Foot terminal installed and configured"
