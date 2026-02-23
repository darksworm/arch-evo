#!/usr/bin/env bash
# Work-specific tools
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Work Tools"

pac_install libreoffice-fresh networkmanager-openvpn

ensure_yay
yay_install slack-desktop kubectl-argo-rollouts-bin kubelogin pritunl-client-bin

log "Work tools installed"
