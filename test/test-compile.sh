#!/usr/bin/env bash
# Test: Verify Hyprland can be installed
set -euo pipefail

echo "=== Hyprland Install Test ==="

# Verify hyprland package exists in official repos
if pacman -Si hyprland &>/dev/null; then
    echo "PASS: hyprland package found in official repos"
else
    echo "FAIL: hyprland package not found"
    exit 1
fi

echo "=== Hyprland install test complete ==="
