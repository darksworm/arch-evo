#!/usr/bin/env bash
# Backup/restore tools
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Backup & Restore Tools"

pac_install rsync

log "Backup tools installed (scripts deployed via 15_bin_scripts.sh)"
