#!/usr/bin/env bash
# Docker engine from Docker's official apt repo
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Docker"

. /etc/os-release
add_apt_repo docker https://download.docker.com/linux/ubuntu/gpg \
    "deb [arch=$(dpkg --print-architecture) signed-by=@KEYRING@] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable"

apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker "${USER}"

enable_service docker.service

log "Docker installed. Log out and back in for group membership to take effect."
