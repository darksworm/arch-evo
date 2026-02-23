#!/usr/bin/env bash
#
# vm-setup.sh — Create and boot a QEMU x86_64 VM for arch-evo testing
#
# Uses QEMU TCG (multi-threaded) to run an x86_64 Arch ISO on Apple Silicon.
# Boots in UEFI mode with NAT + SSH port forwarding on port 2222.
#
# Usage:
#   ./test/vm-setup.sh              # Headless: boot, auto-configure SSH, wait
#   ./test/vm-setup.sh --interactive # Foreground with serial console attached
#   ./test/vm-setup.sh --gui         # Graphical window (for testing MangoWC/Wayland)

set -euo pipefail

VM_NAME="arch-evo-test"
ISO="/Users/ilmars/Downloads/archlinux-2026.02.01-x86_64.iso"
VM_DIR="$HOME/.arch-evo-vm"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DISK="${VM_DIR}/${VM_NAME}.qcow2"
PIDFILE="${VM_DIR}/${VM_NAME}.pid"
OVMF="/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
EFIVARS="${VM_DIR}/efivars.fd"
OVMF_VARS_TEMPLATE="/opt/homebrew/share/qemu/edk2-i386-vars.fd"
SERIAL_FIFO="${VM_DIR}/serial.in"
CONSOLE_LOG="${VM_DIR}/console.log"
SSH_PASSWORD="archevo"
SSH_PORT=2222

MODE="headless"
case "${1:-}" in
    --interactive) MODE="interactive" ;;
    --gui)         MODE="gui" ;;
esac

# ── Preflight checks ──────────────────────────────────────────────

if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "ERROR: qemu-system-x86_64 not found. Install with: brew install qemu" >&2
    exit 1
fi

if [[ ! -f "$ISO" ]]; then
    echo "ERROR: Arch ISO not found at $ISO" >&2
    exit 1
fi

if [[ ! -f "$OVMF" ]]; then
    echo "ERROR: OVMF firmware not found at $OVMF" >&2
    exit 1
fi

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "ERROR: VM already running (PID $(cat "$PIDFILE")). Run vm-teardown.sh first." >&2
    exit 1
fi

# ── Create VM directory and disk ──────────────────────────────────

mkdir -p "$VM_DIR"

if [[ ! -f "$DISK" ]]; then
    echo "Creating 40 GB qcow2 disk..."
    qemu-img create -f qcow2 "$DISK" 40G
fi

# Copy OVMF vars template (writable per-VM EFI variable store)
if [[ ! -f "$EFIVARS" ]]; then
    cp "$OVMF_VARS_TEMPLATE" "$EFIVARS"
fi

# Common QEMU arguments
QEMU_ARGS=(
    -machine q35
    -accel tcg,tb-size=2048
    -cpu qemu64
    -m 8192
    -smp 1
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF"
    -drive "if=pflash,format=raw,file=$EFIVARS"
    -drive "file=$DISK,format=qcow2,if=virtio,cache=writeback,discard=unmap"
    -cdrom "$ISO"
    -boot d
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22"
    -device virtio-net-pci,netdev=net0
    -fsdev "local,id=archevo,path=$REPO_DIR,security_model=none"
    -device "virtio-9p-pci,fsdev=archevo,mount_tag=arch-evo"
    -pidfile "$PIDFILE"
)

# ── Interactive mode (serial console) ─────────────────────────────

if [[ "$MODE" == "interactive" ]]; then
    echo "Starting QEMU VM (interactive, serial console attached)..."
    echo ""
    echo "  Ctrl-a h  — QEMU keyboard help"
    echo "  Ctrl-a x  — Kill VM"
    echo "  Ctrl-a c  — Toggle QEMU monitor"
    echo ""
    echo "Once you see the root shell, run:"
    echo "  mount -t 9p -o trans=virtio arch-evo /mnt -oversion=9p2000.L"
    echo "  echo root:${SSH_PASSWORD} | chpasswd"
    echo "  systemctl start sshd"
    echo ""
    echo "The arch-evo repo is mounted at /mnt"
    echo ""
    exec qemu-system-x86_64 "${QEMU_ARGS[@]}" \
        -nographic \
        -serial mon:stdio
fi

# ── GUI mode (graphical window) ───────────────────────────────────

if [[ "$MODE" == "gui" ]]; then
    echo "Starting QEMU VM with graphical display..."
    echo ""
    echo "  The VM window will open shortly."
    echo "  SSH is forwarded on port $SSH_PORT (after you start sshd)."
    echo ""
    echo "  Once booted, in the VM console run:"
    echo "    mount -t 9p -o trans=virtio arch-evo /mnt -oversion=9p2000.L"
    echo "    echo root:${SSH_PASSWORD} | chpasswd"
    echo "    systemctl start sshd"
    echo ""
    echo "  The arch-evo repo is live-mounted at /mnt"
    echo ""
    exec qemu-system-x86_64 "${QEMU_ARGS[@]}" \
        -display cocoa,show-cursor=on \
        -device virtio-vga \
        -device usb-ehci \
        -device usb-tablet \
        -device usb-kbd
fi

# ── Headless mode ─────────────────────────────────────────────────

echo "Starting QEMU VM (headless, x86_64 via TCG multi-threaded)..."

# Clean up old FIFO/log
rm -f "$SERIAL_FIFO" "$CONSOLE_LOG"
mkfifo "$SERIAL_FIFO"
touch "$CONSOLE_LOG"

# Start QEMU in background
# stdin from FIFO (opened r/w via <> to prevent blocking)
# stdout/stderr to console log
qemu-system-x86_64 "${QEMU_ARGS[@]}" \
    -nographic \
    <> "$SERIAL_FIFO" > "$CONSOLE_LOG" 2>&1 &

QEMU_PID=$!
echo "QEMU started (PID $QEMU_PID)"
echo "Console log: $CONSOLE_LOG"

# Verify QEMU didn't exit immediately
sleep 2
if ! kill -0 "$QEMU_PID" 2>/dev/null; then
    echo "ERROR: QEMU exited immediately. Check $CONSOLE_LOG" >&2
    tail -20 "$CONSOLE_LOG" >&2
    exit 1
fi

# ── Wait for boot ────────────────────────────────────────────────

echo ""
echo "Waiting for Arch ISO to boot (TCG emulation is slow, ~2-4 min)..."

BOOT_TIMEOUT=300
ELAPSED=0
BOOTED=false

while (( ELAPSED < BOOT_TIMEOUT )); do
    if ! kill -0 "$QEMU_PID" 2>/dev/null; then
        echo "ERROR: QEMU process died during boot." >&2
        tail -30 "$CONSOLE_LOG" >&2
        exit 1
    fi

    # Check for root prompt or login prompt in console log
    if grep -qE "(root@archiso|archiso login:)" "$CONSOLE_LOG" 2>/dev/null; then
        BOOTED=true
        break
    fi

    sleep 10
    ELAPSED=$((ELAPSED + 10))
    # Show progress
    printf "\r  %ds elapsed..." "$ELAPSED"
done

echo ""

if ! $BOOTED; then
    echo "ERROR: Timed out waiting for Arch ISO boot (${BOOT_TIMEOUT}s)." >&2
    echo "Last 30 lines of console log:" >&2
    tail -30 "$CONSOLE_LOG" >&2
    exit 1
fi

echo "Arch ISO booted. Configuring SSH..."

# ── Configure SSH via serial console ─────────────────────────────

# Small delay to let the shell fully initialize
sleep 5

# Send commands through the serial FIFO
# If we got "archiso login:" we need to type "root" first
if grep -q "archiso login:" "$CONSOLE_LOG" 2>/dev/null; then
    echo "root" > "$SERIAL_FIFO"
    sleep 3
fi

# Set root password and start sshd
echo "echo root:${SSH_PASSWORD} | chpasswd" > "$SERIAL_FIFO"
sleep 3
echo "systemctl start sshd" > "$SERIAL_FIFO"
sleep 3

# ── Wait for SSH ─────────────────────────────────────────────────

echo "Waiting for SSH on port $SSH_PORT..."

SSH_TIMEOUT=120
ELAPSED=0

while (( ELAPSED < SSH_TIMEOUT )); do
    # Check TCP connectivity (nc -z returns 0 if port is open)
    if nc -z -w 3 localhost "$SSH_PORT" 2>/dev/null; then
        echo ""
        echo "========================================="
        echo " VM is ready! SSH is available."
        echo "========================================="
        echo ""
        echo "  Connect:   ssh -p $SSH_PORT root@localhost"
        echo "  Password:  $SSH_PASSWORD"
        echo "  Shortcut:  ./test/vm-ssh.sh"
        echo ""
        echo "  Push repo: ./test/vm-push.sh"
        echo "  Teardown:  ./test/vm-teardown.sh"
        echo ""
        echo "  Console:   tail -f $CONSOLE_LOG"
        echo "  PID:       $QEMU_PID"
        echo ""
        exit 0
    fi

    sleep 5
    ELAPSED=$((ELAPSED + 5))
    printf "\r  %ds elapsed..." "$ELAPSED"
done

echo ""
echo "ERROR: SSH did not become available after ${SSH_TIMEOUT}s." >&2
echo "The VM is still running (PID $QEMU_PID). Debug with:" >&2
echo "  tail -100 $CONSOLE_LOG" >&2
exit 1
