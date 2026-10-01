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
    brightnessctl \
    playerctl pamixer pavucontrol \
    hyprlock hypridle \
    network-manager-gnome policykit-1-gnome

# ── awww (wallpaper daemon): no release binaries — build with cargo
if ! command -v awww-daemon &>/dev/null; then
    apt_install liblz4-dev libwayland-dev wayland-protocols libxkbcommon-dev
    ensure_mise
    command -v cargo &>/dev/null || mise use --global rust@latest
    AWWW_SRC="${OPT_DIR}/src/awww"
    if [[ -d "${AWWW_SRC}/.git" ]]; then
        git -C "${AWWW_SRC}" pull --ff-only -q
    else
        git clone --depth 1 https://codeberg.org/LGFae/awww "${AWWW_SRC}"
    fi
    log "Building awww (takes a minute)..."
    mise exec rust -- cargo install --locked --root "${HOME}/.local" --path "${AWWW_SRC}/client"
    mise exec rust -- cargo install --locked --root "${HOME}/.local" --path "${AWWW_SRC}/daemon"
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
