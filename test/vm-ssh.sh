#!/usr/bin/env bash
#
# vm-ssh.sh — SSH into the arch-evo-test VM

set -euo pipefail

USER="${1:-root}"
shift 2>/dev/null || true

exec ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -p 2222 \
    "${USER}@localhost" "$@"
