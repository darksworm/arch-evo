#!/usr/bin/env bash
# Fingerprint authentication via fprintd
# Supports ThinkPad T14 Gen 6 (Synaptics 06cb:00f9) and most modern laptops
# Only sudo gets fingerprint (with the lid check); pam-auth-update's fprintd
# profile is left off so it doesn't apply everywhere without the lid check.
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Fingerprint Authentication"

apt_install fprintd libpam-fprintd

# Keep libpam-fprintd's common-auth profile off (it's opt-in, but may have been
# enabled): it would prompt for a finger even with the lid shut, for every PAM
# service. Only the lid-aware sudo lines below should use the reader.
sudo pam-auth-update --disable fprintd

# Lid-check script: skip fingerprint prompt when lid is closed
LID_CHECK=/usr/local/bin/check-lid-open
sudo tee "${LID_CHECK}" > /dev/null <<'LIDEOF'
#!/bin/bash
grep -q "open" /proc/acpi/button/lid/LID*/state
LIDEOF
sudo chmod +x "${LID_CHECK}"

# Enable fprintd for sudo with lid-aware bypass
SUDO_PAM=/etc/pam.d/sudo
if grep -q pam_exec "${SUDO_PAM}"; then
    log "fprintd lid-bypass already configured in sudo PAM"
elif grep -q pam_fprintd "${SUDO_PAM}"; then
    # Upgrade: replace bare fprintd line with lid-check + fprintd
    sudo sed -i "s|^auth sufficient pam_fprintd.so|auth [success=ignore default=1] pam_exec.so quiet ${LID_CHECK}\nauth sufficient pam_fprintd.so|" "${SUDO_PAM}"
    log "fprintd sudo PAM upgraded with lid-close bypass"
else
    # Fresh install
    sudo sed -i "1s|^|auth [success=ignore default=1] pam_exec.so quiet ${LID_CHECK}\nauth sufficient pam_fprintd.so\n|" "${SUDO_PAM}"
    log "fprintd added to sudo PAM with lid-close bypass"
fi

# Fail early if libfprint has no driver for this reader
if ! fprintd-list "${USERNAME}" 2>&1 | grep -q "Fingerprints for user\|has no fingers enrolled"; then
    warn "fprintd found no supported reader — fingerprint auth will not work"
    fprintd-list "${USERNAME}" || true
fi

# hyprlock uses PAM automatically — no extra config needed

enable_service fprintd.service

log "Fingerprint installed. Enroll with: fprintd-enroll"
log "If no device found, check: lsusb | grep -i finger"
