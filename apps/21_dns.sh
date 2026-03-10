#!/usr/bin/env bash
# dnsmasq setup for *.devel and dev.penneo.com -> 10.254.254.254
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "DNS (dnsmasq)"

pac_install dnsmasq

CONF_FILE="/etc/dnsmasq.d/penneo.conf"

if [[ ! -f "$CONF_FILE" ]]; then
    log "Writing dnsmasq config..."
    sudo mkdir -p /etc/dnsmasq.d
    sudo tee "$CONF_FILE" >/dev/null <<'EOF'
address=/devel/10.254.254.254
address=/dev.penneo.com/10.254.254.254
EOF
    log "Config written to ${CONF_FILE}"
else
    log "dnsmasq config already exists at ${CONF_FILE}"
fi

# Point systemd-resolved to dnsmasq for stub listener conflict avoidance
RESOLVED_CONF="/etc/systemd/resolved.conf.d/dnsmasq.conf"
if [[ ! -f "$RESOLVED_CONF" ]]; then
    log "Configuring systemd-resolved to use dnsmasq..."
    sudo mkdir -p /etc/systemd/resolved.conf.d
    sudo tee "$RESOLVED_CONF" >/dev/null <<'EOF'
[Resolve]
DNS=127.0.0.1
DNSStubListener=no
EOF
    sudo systemctl restart systemd-resolved
fi

enable_service dnsmasq.service
sudo systemctl start dnsmasq.service

log "DNS setup complete. Verify with: ping something.devel"
