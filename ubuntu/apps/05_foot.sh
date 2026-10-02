#!/usr/bin/env bash
# Foot terminal emulator (Wayland-native)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Foot Terminal"

apt_install foot foot-terminfo

# Ubuntu's foot (1.25) predates the [colors-dark] section the shared config
# uses, so write a copy with the old [colors] name. Re-run after editing
# conf/foot/foot.ini.
mkdir -p "${HOME}/.config/foot"
rm -f "${HOME}/.config/foot/foot.ini"
sed 's/^\[colors-dark\]$/[colors]/' "${CONF_DIR}/foot/foot.ini" > "${HOME}/.config/foot/foot.ini"
log "Wrote ~/.config/foot/foot.ini (with [colors] for foot $(foot --version | awk '{print $3}'))"

log "Foot terminal installed and configured"
