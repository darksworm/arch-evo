#!/usr/bin/env bash
# Docker engine setup
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Docker"

pac_install docker docker-compose

# Add current user to docker group
sudo usermod -aG docker "${USER}"

enable_service docker.service

log "Docker installed. Log out and back in for group membership to take effect."
