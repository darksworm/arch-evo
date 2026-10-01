#!/usr/bin/env bash
# CLI utilities: btop, bat, yazi (yazi itself comes from mise in 06)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "CLI Utilities"

apt_install btop bat acpi ffmpegthumbnailer poppler-utils

# Ubuntu ships bat as batcat (name clash with another package)
link_bin /usr/bin/batcat bat

# Deploy btop config
deploy_config_dir "${CONF_DIR}/btop" "${HOME}/.config/btop"

log "CLI utilities installed"
