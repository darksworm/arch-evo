#!/usr/bin/env bash
# Fingerprint authentication via fprintd
# Supports ThinkPad T14s Gen 6 (Goodix reader) and most modern laptops
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Fingerprint Authentication"

pac_install fprintd

# Enable fprintd for sudo — insert before existing auth lines
SUDO_PAM=/etc/pam.d/sudo
if ! grep -q pam_fprintd /etc/pam.d/sudo; then
    sudo sed -i '1s/^/auth sufficient pam_fprintd.so\n/' "${SUDO_PAM}"
    log "fprintd added to sudo PAM"
fi

# hyprlock uses PAM automatically — no extra config needed

enable_service fprintd.service

log "Fingerprint installed. Enroll with: fprintd-enroll"
log "If no device found, check: lsusb | grep -i finger"
