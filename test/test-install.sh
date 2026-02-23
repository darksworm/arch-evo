#!/usr/bin/env bash
# Test: Run all app scripts in Docker mode
set -euo pipefail

echo "=== arch-evo Docker Install Test ==="
echo "Running as: $(whoami)"
echo "Mode: ${INSTALLER_MODE:-unknown}"

cd /opt/arch

# Source config to verify it loads
source .config
echo "Config loaded successfully"

# Verify library functions
is_docker && echo "PASS: is_docker() = true" || echo "FAIL: is_docker() should be true"

# Run applications.sh
echo ""
echo "=== Running applications.sh ==="
sudo -u testuser bash applications.sh

echo ""
echo "=== Install test complete ==="
