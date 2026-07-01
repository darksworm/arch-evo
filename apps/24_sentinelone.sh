#!/usr/bin/env bash
# Install the SentinelOne agent from the vendor .deb on Arch.
#
# There is no real Arch package; the AUR one wraps an outdated .deb. The .deb is
# self-contained and its maintainer scripts are distro-agnostic bash (they only
# need useradd/groupadd, systemctl, setpriv and coreutils), so we drive them
# directly instead of going through dpkg:
#   1. preinst install   -> create sentinelone user/group + /opt/sentinelone
#   2. unpack data.tar.xz -> lay files under /opt/sentinelone and /etc
#   3. postinst configure -> permissions, systemd unit, sentinelctl in PATH
#   4. register with the management console using a site token (option A)
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "SentinelOne Agent"

# Newest .deb wins if several were downloaded; override with S1_DEB=/path.
DEB="${S1_DEB:-$(ls -t "${HOME}"/Downloads/SentinelAgent_*.deb \
    "$(dirname "$(dirname "${BASH_SOURCE[0]}")")"/SentinelAgent_*.deb 2>/dev/null | head -1 || true)}"

# Site/registration token from the SentinelOne console. Pass via env or arg.
S1_TOKEN="${S1_AGENT_MANAGEMENT_TOKEN:-${1:-}}"

CTL="/opt/sentinelone/bin/sentinelctl"

[[ -n "$DEB" && -f "$DEB" ]] || die "No SentinelAgent_*.deb found. Set S1_DEB=/path/to/agent.deb"
DEB="$(realpath "$DEB")"   # absolute: we cd into a tmp dir before unpacking

if [[ -d /opt/sentinelone || -e "$CTL" ]]; then
    log "SentinelOne already installed at /opt/sentinelone, skipping unpack."
else
    for c in ar useradd groupadd setpriv systemctl; do
        command -v "$c" >/dev/null || die "Required tool missing: $c"
    done

    log "Using package: $DEB"
    work="$(mktemp -d)"
    trap 'rm -rf "$work"' EXIT

    log "Extracting .deb container..."
    ( cd "$work" && ar x "$DEB" && tar xzf control.tar.gz )

    log "Running preinst (creates sentinelone user/group, /opt/sentinelone)..."
    sudo bash "$work/preinst" install

    log "Unpacking agent files to /..."
    sudo tar -C / -xJf "$work/data.tar.xz"

    log "Running postinst (permissions, systemd unit, sentinelctl in PATH)..."
    sudo bash "$work/postinst" configure
fi

# --- Option A: register after install ---------------------------------------
if [[ -z "$S1_TOKEN" ]]; then
    warn "No site token provided; agent is installed but NOT registered."
    warn "Register later with:"
    warn "  sudo sentinelctl management token set <TOKEN> && sudo sentinelctl control start"
else
    log "Registering agent with management console..."
    sudo "$CTL" management token set "$S1_TOKEN"
    log "Starting agent..."
    sudo "$CTL" control start
    sudo "$CTL" control status || true
    log "Agent registered and started."
fi

log "Done. Check status any time with: sudo sentinelctl control status"
