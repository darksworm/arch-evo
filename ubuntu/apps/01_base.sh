#!/usr/bin/env bash
# Base packages the other scripts rely on (curl, git, build tools, dialog)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Base Packages"

apt_install \
    curl wget git ca-certificates gnupg software-properties-common \
    build-essential pkg-config unzip xz-utils jq dialog rsync

ensure_mise

log "Base packages installed"
