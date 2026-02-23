#!/usr/bin/env bash
# arch-evo: TUI-driven Arch Linux installer
# Handles partitioning, LUKS encryption, and base system install
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.config"

# ── Docker mode: skip hardware install ──────────────────────────
if is_docker; then
    log "Docker mode detected — skipping partitioning and base install"
    log "Proceeding to application setup..."
    exec bash "${SCRIPT_DIR}/applications.sh"
fi

# ── Preflight ───────────────────────────────────────────────────
if ! is_efi; then
    die "This installer requires UEFI boot mode"
fi

if [[ "$(id -u)" -ne 0 ]]; then
    die "This script must be run as root"
fi

pacman -Sy --noconfirm dialog

# ── Welcome ─────────────────────────────────────────────────────
dialog_msg "arch-evo Installer" \
    "Welcome to the arch-evo Arch Linux installer.\n\n\
This will:\n\
  1. Partition & encrypt a disk (LUKS)\n\
  2. Install the base system\n\
  3. Configure bootloader & users\n\
  4. Run application setup\n\n\
Make sure you have a working internet connection."

# ── Disk Selection ──────────────────────────────────────────────
section "Disk Selection"

declare -a disk_items=()
while IFS= read -r line; do
    name=$(echo "${line}" | awk '{print $1}')
    size=$(echo "${line}" | awk '{print $2}')
    disk_items+=("${name}" "${size}")
done < <(list_disks)

if [[ ${#disk_items[@]} -eq 0 ]]; then
    die "No disks found"
fi

dialog_menu "Disk Selection" "Select the disk to install Arch Linux on:\n\n⚠ ALL DATA WILL BE ERASED" "${disk_items[@]}" || die "Disk selection cancelled"
INSTALL_DISK="${_dialog_result}"

# ── Partition Sizing ────────────────────────────────────────────
section "Partition Configuration"

dialog_input "EFI Partition" "EFI partition size (MiB):" "512" || die "Cancelled"
EFI_SIZE="${_dialog_result}"

# ── LUKS Password ──────────────────────────────────────────────
section "Encryption"

dialog_password_confirm "LUKS Encryption" "Enter encryption password for ${INSTALL_DISK}:" || die "Cancelled"
LUKS_PASSWORD="${_dialog_result}"

# ── Hostname ────────────────────────────────────────────────────
dialog_input "Hostname" "Enter hostname:" "${HOSTNAME}" || die "Cancelled"
SET_HOSTNAME="${_dialog_result}"

# ── Username ────────────────────────────────────────────────────
dialog_input "User Account" "Enter username:" "${USERNAME}" || die "Cancelled"
INSTALL_USER="${_dialog_result}"

dialog_password_confirm "User Password" "Enter password for ${INSTALL_USER}:" || die "Cancelled"
USER_PASSWORD="${_dialog_result}"

# ── Root Password ───────────────────────────────────────────────
dialog_password_confirm "Root Password" "Enter root password:" || die "Cancelled"
ROOT_PASSWORD="${_dialog_result}"

# ── Confirmation ────────────────────────────────────────────────
UCODE=$(get_ucode_package)
PART_EFI=$(get_disk_partition "${INSTALL_DISK}" 1)
PART_ROOT=$(get_disk_partition "${INSTALL_DISK}" 2)

dialog_summary "Confirm Installation" \
    "Disk:          ${INSTALL_DISK}" \
    "EFI Partition: ${PART_EFI} (${EFI_SIZE} MiB)" \
    "Root Partition: ${PART_ROOT} (LUKS encrypted, rest of disk)" \
    "Hostname:      ${SET_HOSTNAME}" \
    "Username:      ${INSTALL_USER}" \
    "CPU Microcode: ${UCODE:-none}" \
    "Timezone:      ${TIMEZONE}" \
    "Locale:        ${LOCALE_MAIN}" \
    "" \
    "⚠ This will DESTROY all data on ${INSTALL_DISK}!" \
    || die "Installation cancelled by user"

# ── Partitioning ────────────────────────────────────────────────
section "Partitioning ${INSTALL_DISK}"

log "Wiping partition table..."
sgdisk --zap-all "${INSTALL_DISK}"

log "Creating EFI partition (${EFI_SIZE} MiB)..."
sgdisk -n 1:0:+${EFI_SIZE}M -t 1:ef00 "${INSTALL_DISK}"

log "Creating root partition (remainder)..."
sgdisk -n 2:0:0 -t 2:8309 "${INSTALL_DISK}"

partprobe "${INSTALL_DISK}"
sleep 2

# ── LUKS Encryption ────────────────────────────────────────────
section "Encrypting ${PART_ROOT}"

echo -n "${LUKS_PASSWORD}" | cryptsetup luksFormat --type luks2 "${PART_ROOT}" -
echo -n "${LUKS_PASSWORD}" | cryptsetup open "${PART_ROOT}" cryptroot -

# ── Filesystem Creation ────────────────────────────────────────
section "Creating Filesystems"

log "Formatting EFI partition..."
mkfs.fat -F32 "${PART_EFI}"

log "Formatting root partition..."
mkfs.ext4 /dev/mapper/cryptroot

# ── Mounting ───────────────────────────────────────────────────
section "Mounting Filesystems"

mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot/efi
mount "${PART_EFI}" /mnt/boot/efi

# ── Pacstrap ───────────────────────────────────────────────────
section "Installing Base System"

PACSTRAP_PACKAGES=(
    base base-devel linux linux-firmware
    vim sudo git networkmanager
    grub efibootmgr os-prober
    dialog
)

if [[ -n "${UCODE}" ]]; then
    PACSTRAP_PACKAGES+=("${UCODE}")
fi

log "Running pacstrap..."
pacstrap /mnt "${PACSTRAP_PACKAGES[@]}"

# ── Fstab ──────────────────────────────────────────────────────
section "Generating fstab"

genfstab -U /mnt >> /mnt/etc/fstab

# ── Copy repo into chroot ─────────────────────────────────────
log "Copying arch-evo to /mnt/opt/arch..."
mkdir -p /mnt/opt/arch
cp -r "${SCRIPT_DIR}/." /mnt/opt/arch/

# ── Export variables for chroot ────────────────────────────────
cat > /mnt/opt/arch/.install-vars <<EOF
SET_HOSTNAME="${SET_HOSTNAME}"
INSTALL_USER="${INSTALL_USER}"
USER_PASSWORD="${USER_PASSWORD}"
ROOT_PASSWORD="${ROOT_PASSWORD}"
INSTALL_DISK="${INSTALL_DISK}"
PART_ROOT="${PART_ROOT}"
TIMEZONE="${TIMEZONE}"
LOCALE_MAIN="${LOCALE_MAIN}"
LOCALE_EXTRA="${LOCALE_EXTRA}"
KEYMAP="${KEYMAP}"
EOF

# ── Chroot ─────────────────────────────────────────────────────
section "Entering chroot"

arch-chroot /mnt bash /opt/arch/chroot.sh

# ── Cleanup ────────────────────────────────────────────────────
section "Cleanup"

rm -f /mnt/opt/arch/.install-vars

log "Unmounting filesystems..."
umount -R /mnt

log ""
log "Installation complete!"
log "Remove the installation media and reboot."
log ""
