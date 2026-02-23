#!/usr/bin/env bash
# arch-evo: TUI-driven Arch Linux installer
# Handles partitioning, LUKS encryption, and base system install
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Copy repo locally if running from a 9p mount ────────────────
# Bash can lose access to the script mid-execution on 9p/network mounts
if [[ "${ARCH_EVO_LOCAL:-}" != "1" ]] && mountpoint -q "$(df --output=target "$SCRIPT_DIR" 2>/dev/null | tail -1)" 2>/dev/null; then
    LOCAL_DIR="/root/arch-evo-local"
    echo "[INFO] Copying repo to $LOCAL_DIR to avoid 9p read errors..."
    rm -rf "$LOCAL_DIR"
    mkdir -p "$LOCAL_DIR"
    tar -C "$SCRIPT_DIR" --exclude='.git' --exclude='test' -cf - . | tar -C "$LOCAL_DIR" -xf -
    echo "[INFO] Re-launching from local copy."
    exec env ARCH_EVO_LOCAL=1 bash "$LOCAL_DIR/install.sh" "$@"
fi

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

# ── Pacman config: mirrors & parallel downloads ──────────────────
cat > /etc/pacman.d/mirrorlist <<'MIRRORS'
Server = https://mirrors.dotsrc.org/archlinux/$repo/os/$arch
Server = https://mirror.one.com/archlinux/$repo/os/$arch
Server = https://ftp.acc.umu.se/mirror/archlinux/$repo/os/$arch
Server = https://mirror.archlinux.no/$repo/os/$arch
Server = https://ftp.fau.de/archlinux/$repo/os/$arch
MIRRORS

sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf

pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm archlinux-keyring dialog

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
mkdir -p /mnt/boot
mount "${PART_EFI}" /mnt/boot

# ── Pacstrap ───────────────────────────────────────────────────
section "Installing Base System"

PACSTRAP_PACKAGES=(
    base base-devel linux linux-firmware
    neovim sudo git networkmanager openssh
    efibootmgr
    dialog
)

if [[ -n "${UCODE}" ]]; then
    PACSTRAP_PACKAGES+=("${UCODE}")
fi

log "Running pacstrap..."
pacstrap /mnt "${PACSTRAP_PACKAGES[@]}"

# ── Copy pacman config to installed system ────────────────────
log "Copying mirrorlist and pacman.conf to installed system..."
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
cp /etc/pacman.conf /mnt/etc/pacman.conf

# ── Fstab ──────────────────────────────────────────────────────
section "Generating fstab"

genfstab -U /mnt >> /mnt/etc/fstab

# ── Copy repo into chroot ─────────────────────────────────────
log "Copying arch-evo to /mnt/opt/arch..."
mkdir -p /mnt/opt/arch
# Use tar to reliably copy across filesystem boundaries (e.g. 9p mounts)
tar -C "${SCRIPT_DIR}" --exclude='.git' --exclude='test' -cf - . | tar -C /mnt/opt/arch -xf -

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
