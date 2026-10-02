#!/usr/bin/env bash
# Wayland desktop tools: bar, launcher, notifications, lock, screenshots,
# wallpaper, monitor profiles
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "Wayland Tools"

# hyprlock / hypridle / hyprsunset come from the cppiber PPA (added in 11)
add_ppa cppiber/hyprland
apt_install \
    waybar fuzzel dunst libnotify-bin hyprsunset \
    grim slurp wl-clipboard cliphist \
    brightnessctl socat \
    playerctl pamixer pavucontrol \
    hyprlock hypridle \
    network-manager-gnome policykit-1-gnome

# ── awww (wallpaper daemon): no release binaries — build the latest tag.
# Build the whole workspace: building daemon/ alone unifies rustix without its
# std feature and fails to compile (rustix::stdio::stdout becomes unsafe).
if [[ ! -x "${LOCAL_BIN}/awww-daemon" ]]; then
    apt_install liblz4-dev libwayland-dev wayland-protocols libxkbcommon-dev
    ensure_mise
    command -v cargo &>/dev/null || mise use --global rust@latest
    AWWW_TAG=$(curl -fsSL "https://codeberg.org/api/v1/repos/LGFae/awww/releases?limit=1" | jq -r '.[0].tag_name')
    AWWW_SRC="${OPT_DIR}/src/awww"
    rm -rf "${AWWW_SRC}"
    git clone --depth 1 --branch "${AWWW_TAG}" https://codeberg.org/LGFae/awww "${AWWW_SRC}"
    log "Building awww ${AWWW_TAG} (takes a few minutes)..."
    (cd "${AWWW_SRC}" && mise exec rust -- cargo build --release --locked)
    mkdir -p "${LOCAL_BIN}"
    install -m755 "${AWWW_SRC}/target/release/awww" "${AWWW_SRC}/target/release/awww-daemon" "${LOCAL_BIN}/"
fi

# ── matuwall (wallpaper picker): upstream prebuilt binary
MATUWALL_TAG=$(gh_latest_tag naurissteins/Matuwall)
install_tarball \
    "https://github.com/naurissteins/Matuwall/releases/download/${MATUWALL_TAG}/matuwall-${MATUWALL_TAG#v}-x86_64-linux.tar.xz" \
    "${OPT_DIR}/matuwall"
link_bin "${OPT_DIR}/matuwall/usr/bin/matuwall"

# ── hyprdynamicmonitors (monitor profiles): upstream prebuilt binary
install_tarball \
    https://github.com/fiffeek/hyprdynamicmonitors/releases/latest/download/hyprdynamicmonitors_Linux_x86_64.tar.gz \
    "${OPT_DIR}/hyprdynamicmonitors"
link_bin "${OPT_DIR}/hyprdynamicmonitors/hyprdynamicmonitors"

# Deploy configs
deploy_config_dir "${CONF_DIR}/waybar" "${HOME}/.config/waybar"
deploy_config "${CONF_DIR}/dunst/dunstrc" "${HOME}/.config/dunst/dunstrc"
deploy_config "${CONF_DIR}/hypr/hyprlock.conf" "${HOME}/.config/hypr/hyprlock.conf"

# Hyprlock parallax assets (background + mountain foreground)
mkdir -p "${HOME}/.config/hypr/hyprlock"
cp -f "${REPO_DIR}/static/hyprlock/wall.jpg" "${HOME}/.config/hypr/hyprlock/wall.jpg"
cp -f "${REPO_DIR}/static/hyprlock/fg.png" "${HOME}/.config/hypr/hyprlock/fg.png"
deploy_config "${CONF_DIR}/hypr/hypridle.conf" "${HOME}/.config/hypr/hypridle.conf"
deploy_config "${CONF_DIR}/hypr/hyprsunset.conf" "${HOME}/.config/hypr/hyprsunset.conf"
deploy_config "${CONF_DIR}/fuzzel/fuzzel.ini" "${HOME}/.config/fuzzel/fuzzel.ini"
deploy_config "${CONF_DIR}/matuwall/config.json" "${HOME}/.config/matuwall/config.json"
for f in "${CONF_DIR}"/hypr/scripts/*; do
    deploy_config "${f}" "${HOME}/.config/hypr/scripts/$(basename "${f}")"
done

log "Wayland tools installed and configured"
