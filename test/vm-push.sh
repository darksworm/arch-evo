#!/usr/bin/env bash
#
# vm-push.sh — SCP the arch-evo repo into the running QEMU VM
#
# Prerequisites: VM is running and sshd is started (see vm-setup.sh).
# Excludes .git and test/ to keep the transfer small.

set -euo pipefail

HOST="root@localhost"
PORT=2222
REMOTE_DIR="/opt/arch"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

echo "Pushing arch-evo repo to VM..."
echo "  Local:  $REPO_DIR"
echo "  Remote: $HOST:$REMOTE_DIR"
echo ""

# Create remote directory and copy files
# Exclude .git and test artifacts to keep the transfer small
ssh $SSH_OPTS -p "$PORT" "$HOST" "mkdir -p $REMOTE_DIR"

scp $SSH_OPTS -P "$PORT" -r \
    "$REPO_DIR/install.sh" \
    "$REPO_DIR/chroot.sh" \
    "$REPO_DIR/applications.sh" \
    "$REPO_DIR/lib" \
    "$REPO_DIR/conf" \
    "$REPO_DIR/apps" \
    "$REPO_DIR/bin" \
    "$REPO_DIR/static" \
    "$HOST:$REMOTE_DIR/"

echo ""
echo "Done. Files pushed to $HOST:$REMOTE_DIR"
echo ""
echo "SSH in and run the installer:"
echo "  ssh -p $PORT $HOST"
echo "  cd $REMOTE_DIR && bash install.sh"
