#!/usr/bin/env bash
# Post-install cleanup
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Cleanup"

# Clean package cache (keep last 2 versions)
if command -v paccache &>/dev/null; then
    sudo paccache -rk2
fi

# Clean yay cache
if command -v yay &>/dev/null; then
    yay -Scc --noconfirm 2>/dev/null || true
fi

log "Cleanup complete"
log ""
log "Installation finished! Reboot to start using MangoWC."
log "After reboot, MangoWC starts automatically via tty1 autologin."
