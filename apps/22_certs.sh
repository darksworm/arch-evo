#!/usr/bin/env bash
# Install root CA certificates for Penneo QS environments
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Root CA Certificates"

TRUST_DIR="/etc/ca-certificates/trust-source/anchors"
ENDPOINTS=(
    "ss.stg.qs.penneo.cloud:stg-qs-penneo"
    "ss.prod.qs.penneo.cloud:prod-qs-penneo"
)

for entry in "${ENDPOINTS[@]}"; do
    host="${entry%%:*}"
    label="${entry##*:}"
    dest="${TRUST_DIR}/${label}-root-ca.pem"

    if [[ -f "$dest" ]]; then
        log "${label}: root CA already installed at ${dest}"
        continue
    fi

    log "${label}: fetching certificate chain from ${host}..."

    # Grab the full chain; the last cert is the root (or highest CA sent)
    chain=$(openssl s_client -connect "${host}:443" -showcerts </dev/null 2>/dev/null)

    # Extract the last certificate block in the chain
    root_pem=$(echo "$chain" \
        | awk '/-----BEGIN CERTIFICATE-----/{buf=""; capture=1} capture{buf=buf $0 ORS} /-----END CERTIFICATE-----/{last=buf; capture=0} END{printf "%s", last}')

    if [[ -z "$root_pem" ]]; then
        log "${label}: ERROR - could not extract certificate from ${host}"
        continue
    fi

    # Show what we got
    subject=$(echo "$root_pem" | openssl x509 -noout -subject 2>/dev/null || true)
    issuer=$(echo "$root_pem" | openssl x509 -noout -issuer 2>/dev/null || true)
    log "${label}: ${subject}"
    log "${label}: ${issuer}"

    # Install
    sudo mkdir -p "$TRUST_DIR"
    echo "$root_pem" | sudo tee "$dest" >/dev/null
    log "${label}: installed to ${dest}"
done

log "Updating system trust store..."
sudo update-ca-trust

log "Root CA certificates installed. Verify with: trust list | grep -i penneo"

# Import into Zen/Firefox NSS databases so the browser trusts them directly
NSS_DBS=()
while IFS= read -r -d '' db; do
    NSS_DBS+=("$(dirname "$db")")
done < <(find "${HOME}/.config/zen" "${HOME}/.mozilla" -name "cert9.db" -print0 2>/dev/null)

if [[ ${#NSS_DBS[@]} -gt 0 ]]; then
    for db_dir in "${NSS_DBS[@]}"; do
        for entry in "${ENDPOINTS[@]}"; do
            label="${entry##*:}"
            pem="${TRUST_DIR}/${label}-root-ca.pem"
            [[ -f "$pem" ]] || continue
            certutil -d "sql:${db_dir}" -A -t "C,," -n "${label}-root-ca" -i "$pem"
        done
        log "Imported certs into NSS database: ${db_dir}"
    done
else
    log "No Zen/Firefox NSS databases found, skipping browser import"
fi
