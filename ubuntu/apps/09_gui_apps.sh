#!/usr/bin/env bash
# GUI apps: Zen browser, Spotify, Vesktop
set -euo pipefail
source "$(dirname "$(dirname "${BASH_SOURCE[0]}")")/.config"

section "GUI Applications"

# ── Zen browser: official tarball, self-updates since the dir is user-owned
ZEN_DIR="${OPT_DIR}/zen"
if [[ -x "${ZEN_DIR}/zen/zen" ]]; then
    log "Zen already installed at ${ZEN_DIR} (updates itself)"
else
    install_tarball \
        https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz \
        "${ZEN_DIR}"
fi
# hyprland.lua, zshenv ($BROWSER) and the desktop entry call it zen-browser
link_bin "${ZEN_DIR}/zen/zen" zen-browser
mkdir -p "${XDG_DATA_HOME}/applications"
cat > "${XDG_DATA_HOME}/applications/zen.desktop" <<DESKTOP
[Desktop Entry]
Name=Zen Browser
Exec=${LOCAL_BIN}/zen-browser %u
Icon=${ZEN_DIR}/zen/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=zen
DESKTOP
xdg-settings set default-web-browser zen.desktop || warn "Could not set Zen as default browser"

# ── Spotify: official apt repo
add_apt_repo spotify https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.gpg \
    "deb [signed-by=@KEYRING@] https://repository.spotify.com stable non-free"
apt_install spotify-client
ln -sf "${CONF_DIR}/spotify-flags.conf" "${HOME}/.config/spotify-flags.conf"

# ── Vesktop: upstream .deb (keeps the plain `vesktop` command pyprland uses)
VESKTOP_TAG=$(gh_latest_tag Vencord/Vesktop)
install_deb_url \
    "https://github.com/Vencord/Vesktop/releases/download/${VESKTOP_TAG}/vesktop_${VESKTOP_TAG#v}_amd64.deb"

log "GUI applications installed"
