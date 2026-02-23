#!/usr/bin/env bash
# Development tools and languages
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Development Tools"

pac_install \
    go cmake ninja \
    docker \
    kubectl helm k9s \
    ripgrep fzf jq git-delta git-lfs github-cli \
    python wget httpie parallel ffmpeg mkcert \
    mise kustomize krew dive uv ghq

ensure_yay
yay_install aws-cli-bin trivy-bin act-bin

# Claude Code (Anthropic's native installer — auto-updates)
if ! command -v claude &>/dev/null; then
    run_as_user "${USERNAME}" "curl -fsSL https://claude.ai/install.sh | bash"
fi

# Deploy k9s skin
deploy_config "${CONF_DIR}/k9s/skin.yaml" "${HOME}/.config/k9s/skins/skin.yaml"

log "Development tools installed"
