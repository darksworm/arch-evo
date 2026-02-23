#!/usr/bin/env bash
# Development tools and languages
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Development Tools"

pac_install \
    go cmake ninja \
    docker docker-compose \
    kubectl helm k9s \
    ripgrep fzf jq git-delta git-lfs github-cli \
    python pyenv wget httpie parallel ffmpeg mkcert \
    jdk11-openjdk jdk17-openjdk jdk21-openjdk

ensure_yay
yay_install \
    fnm kustomize krew \
    aws-cli-v2 dive trivy act uv jenv

# Deploy k9s skin
deploy_config "${CONF_DIR}/k9s/skin.yaml" "${HOME}/.config/k9s/skins/skin.yaml"

log "Development tools installed"
