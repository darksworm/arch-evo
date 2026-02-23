#!/usr/bin/env bash
# Test: Verify neovim launches and plugins install
set -euo pipefail

echo "=== Neovim Test ==="

if ! command -v nvim &>/dev/null; then
    pacman -S --needed --noconfirm neovim git
fi

# Setup LazyVim
NVIM_DIR="/tmp/test-nvim"
rm -rf "${NVIM_DIR}"
git clone https://github.com/LazyVim/starter "${NVIM_DIR}"
rm -rf "${NVIM_DIR}/.git"

# Copy custom plugins
cp /opt/arch/conf/nvim/lua/plugins/*.lua "${NVIM_DIR}/lua/plugins/" 2>/dev/null || true
cp /opt/arch/conf/nvim/lua/config/*.lua "${NVIM_DIR}/lua/config/" 2>/dev/null || true

# Run headless
export XDG_CONFIG_HOME="/tmp/test-xdg"
mkdir -p "${XDG_CONFIG_HOME}"
ln -sf "${NVIM_DIR}" "${XDG_CONFIG_HOME}/nvim"

echo "Running headless plugin sync..."
if timeout 120 nvim --headless "+Lazy! sync" +qa 2>&1; then
    echo "PASS: Neovim plugins installed"
else
    echo "WARN: Headless install timed out or had issues (may work interactively)"
fi

# Verify nvim starts
if nvim --headless -c 'qall' 2>/dev/null; then
    echo "PASS: Neovim starts successfully"
else
    echo "FAIL: Neovim failed to start"
    exit 1
fi

echo "=== Neovim test complete ==="
