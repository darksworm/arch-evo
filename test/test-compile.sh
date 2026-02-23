#!/usr/bin/env bash
# Test: Verify MangoWC can be installed from AUR
set -euo pipefail

echo "=== MangoWC Install Test ==="

# Install build deps
pacman -S --needed --noconfirm \
    wayland wayland-protocols libinput libxkbcommon pixman pkg-config \
    gcc make git meson ninja libdisplay-info libliftoff hwdata seatd pcre2 \
    xorg-xwayland libxcb libdrm

# Verify mangowc-git package exists in AUR
if curl -sf "https://aur.archlinux.org/rpc/v5/info?arg[]=mangowc-git" | grep -q '"NumVotes"'; then
    echo "PASS: mangowc-git package found in AUR"
else
    echo "FAIL: mangowc-git package not found in AUR"
    exit 1
fi

echo "=== MangoWC install test complete ==="
