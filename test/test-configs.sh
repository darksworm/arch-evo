#!/usr/bin/env bash
# Test: Validate syntax of all config files
set -euo pipefail

echo "=== Config Validation Test ==="

CONF_DIR="/opt/arch/conf"
PASS=0
FAIL=0

check() {
    local desc="$1"
    if eval "$2" 2>/dev/null; then
        echo "PASS: ${desc}"
        ((PASS++))
    else
        echo "FAIL: ${desc}"
        ((FAIL++))
    fi
}

# Shell scripts — check syntax
for f in /opt/arch/*.sh /opt/arch/apps/*.sh /opt/arch/lib/*.sh /opt/arch/bin/*; do
    [[ -f "$f" ]] || continue
    check "bash syntax: $(basename "$f")" "bash -n '$f'"
done

# JSON/JSONC — use python for validation
if command -v python3 &>/dev/null; then
    for f in "${CONF_DIR}"/waybar/config.jsonc; do
        [[ -f "$f" ]] || continue
        # Strip // comments for JSONC, then validate
        check "json: $(basename "$f")" "sed 's|//.*||' '$f' | python3 -m json.tool > /dev/null"
    done
fi

# YAML — use python if pyyaml available
if python3 -c "import yaml" 2>/dev/null; then
    for f in "${CONF_DIR}"/k9s/*.yaml "${CONF_DIR}"/interception/*.yaml; do
        [[ -f "$f" ]] || continue
        check "yaml: $(basename "$f")" "python3 -c \"import yaml; yaml.safe_load(open('$f'))\""
    done
fi

# TOML — starship config
if command -v starship &>/dev/null; then
    check "toml: starship.toml" "starship config 2>/dev/null"
fi

# INI — basic check (no empty file)
for f in "${CONF_DIR}"/foot/foot.ini "${CONF_DIR}"/gtk-3.0/settings.ini "${CONF_DIR}"/gtk-4.0/settings.ini; do
    [[ -f "$f" ]] || continue
    check "ini non-empty: $(basename "$f")" "[[ -s '$f' ]]"
done

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[[ ${FAIL} -eq 0 ]] || exit 1
