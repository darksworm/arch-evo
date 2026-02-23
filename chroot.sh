#!/usr/bin/env bash
# arch-evo: In-chroot system configuration
# Run by install.sh via arch-chroot
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.config"

# Load install variables
if [[ -f "${SCRIPT_DIR}/.install-vars" ]]; then
    source "${SCRIPT_DIR}/.install-vars"
fi

# ── Timezone ───────────────────────────────────────────────────
section "Timezone"

ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc
log "Timezone set to ${TIMEZONE}"

# ── Locale ─────────────────────────────────────────────────────
section "Locale"

sed -i "s/^#${LOCALE_MAIN}/${LOCALE_MAIN}/" /etc/locale.gen
sed -i "s/^#${LOCALE_EXTRA}/${LOCALE_EXTRA}/" /etc/locale.gen
locale-gen

echo "LANG=${LOCALE_MAIN}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
log "Locale set to ${LOCALE_MAIN}"

# ── Hostname ───────────────────────────────────────────────────
section "Hostname"

echo "${SET_HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${SET_HOSTNAME}.localdomain ${SET_HOSTNAME}
EOF
log "Hostname set to ${SET_HOSTNAME}"

# ── mkinitcpio ─────────────────────────────────────────────────
section "Initramfs"

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
log "Initramfs rebuilt with encrypt hook"

# ── Bootloader ─────────────────────────────────────────────────
section "Bootloader (GRUB)"

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB

# Configure GRUB for LUKS
CRYPT_UUID=$(blkid -s UUID -o value "${PART_ROOT}")
sed -i "s|^GRUB_CMDLINE_LINUX=\"\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${CRYPT_UUID}:cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
log "GRUB installed and configured with LUKS"

# ── Root Password ──────────────────────────────────────────────
section "Root Password"

echo "root:${ROOT_PASSWORD}" | chpasswd
log "Root password set"

# ── User Setup ─────────────────────────────────────────────────
section "User: ${INSTALL_USER}"

useradd -m -G wheel,docker -s /bin/bash "${INSTALL_USER}"
echo "${INSTALL_USER}:${USER_PASSWORD}" | chpasswd

# Enable wheel group sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
log "User ${INSTALL_USER} created and added to wheel group"

# ── Services ───────────────────────────────────────────────────
section "Services"

systemctl enable NetworkManager
log "NetworkManager enabled"

# ── Clone repo for user ───────────────────────────────────────
section "Application Setup"

log "Repo available at /opt/arch"
log "Run 'sudo bash /opt/arch/applications.sh' after first boot to install applications"

# Optionally run applications.sh now
if dialog_yesno "Application Setup" "Install applications now?\n\n(You can also do this after first boot)"; then
    sudo -u "${INSTALL_USER}" bash /opt/arch/applications.sh
fi

section "Chroot setup complete"
