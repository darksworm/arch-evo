#!/usr/bin/env bash
# Development tools, languages, Kubernetes and cloud CLIs
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Development Tools"

apt_install \
    golang-go cmake ninja-build unzip \
    ripgrep fzf jq git-delta git-lfs gh \
    python3 python3-venv wget httpie parallel ffmpeg mkcert libnss3-tools \
    awscli

# Everything apt lacks comes from mise (GitHub release binaries)
ensure_mise
deploy_config "${CONF_DIR}/mise/config.toml" "${HOME}/.config/mise/config.toml"
deploy_config "${UBUNTU_CONF_DIR}/mise/ubuntu-tools.toml" "${HOME}/.config/mise/conf.d/ubuntu-tools.toml"
log "Installing mise tools..."
mise install --yes

# Claude Code (Anthropic's native installer — auto-updates)
if ! command -v claude &>/dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

# Deploy k9s skin
deploy_config "${CONF_DIR}/k9s/skin.yaml" "${HOME}/.config/k9s/skins/skin.yaml"

log "Development tools installed"
