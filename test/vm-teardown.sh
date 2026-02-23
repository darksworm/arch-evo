#!/usr/bin/env bash
#
# vm-teardown.sh — Kill the QEMU VM and optionally delete disk/state

set -euo pipefail

VM_NAME="arch-evo-test"
VM_DIR="$HOME/.arch-evo-vm"
PIDFILE="${VM_DIR}/${VM_NAME}.pid"

# Kill the QEMU process if running
if [[ -f "$PIDFILE" ]]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Killing QEMU VM (PID $PID)..."
        kill "$PID"
        sleep 1
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID" 2>/dev/null || true
        fi
        echo "VM stopped."
    else
        echo "VM not running (stale PID file)."
    fi
    rm -f "$PIDFILE"
else
    echo "No PID file found. VM may not be running."
fi

# Ask about deleting disk
if [[ -d "$VM_DIR" ]]; then
    if [[ "${1:-}" == "--delete" ]]; then
        echo "Deleting VM directory: $VM_DIR"
        rm -rf "$VM_DIR"
        echo "Done. All VM files removed."
    else
        echo ""
        echo "VM disk and state preserved at: $VM_DIR"
        echo "To delete everything: $0 --delete"
    fi
fi
