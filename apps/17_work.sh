#!/usr/bin/env bash
# Work-specific tools
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Work Tools"

pac_install libreoffice-fresh networkmanager-openvpn mr

ensure_yay
yay_install slack-desktop kubectl-argo-rollouts kubelogin-oidc pritunl-client

log "Work tools installed"
