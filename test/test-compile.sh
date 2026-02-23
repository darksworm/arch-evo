#!/usr/bin/env bash
# Test: Verify DWL compiles with custom config.h
set -euo pipefail

echo "=== DWL Compile Test ==="

# Install build deps
pacman -S --needed --noconfirm \
    wayland wayland-protocols wlroots libinput libxkbcommon pixman pkg-config \
    gcc make git

# Clone DWL
TMPDIR=$(mktemp -d)
git clone https://codeberg.org/dwl/dwl.git "${TMPDIR}/dwl"

# Copy config
cp /opt/arch/conf/dwl/config.h "${TMPDIR}/dwl/config.h"

# Build
cd "${TMPDIR}/dwl"
if make; then
    echo "PASS: DWL compiled successfully"
else
    echo "FAIL: DWL compilation failed"
    exit 1
fi

# Cleanup
rm -rf "${TMPDIR}"

echo "=== DWL compile test complete ==="
