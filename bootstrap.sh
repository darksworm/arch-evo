#!/usr/bin/env bash
# arch-evo bootstrap — run from a live Arch ISO
# curl -fsSL https://gist.githubusercontent.com/darksworm/GIST_ID/raw/bootstrap.sh | bash
set -euo pipefail

REPO="https://github.com/darksworm/arch-evo.git"
DEST="/opt/arch"

echo "=== arch-evo bootstrap ==="

pacman -Sy --noconfirm git

git clone "${REPO}" "${DEST}"

echo ""
echo "Ready! Run the installer:"
echo "  cd ${DEST} && bash install.sh"
