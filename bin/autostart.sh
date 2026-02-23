#!/usr/bin/env bash
# DWL session autostart — launched by dwl -s
# Wayland equivalent of old xinitrc

# wob (Wayland Overlay Bar) for volume/brightness feedback
mkfifo /tmp/wob.sock 2>/dev/null
tail -f /tmp/wob.sock | wob &

# wallpaper
swaybg -i ~/.local/share/wallpapers/default.jpg -m fill &

# bar
waybar &

# notifications
mako &

# network tray
nm-applet --indicator &

# bluetooth tray
blueman-applet &

# screen idle/lock
swayidle -w \
    timeout 300 'swaylock' \
    timeout 600 'wlopm --off \*' \
        resume 'wlopm --on \*' \
    before-sleep 'swaylock' &

# night light
gammastep -l 56.9:24.1 -t 6500:4200 &

# polkit agent (for password prompts)
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# ssh agent
eval $(ssh-agent) > /dev/null

# battery monitor
while true; do
    ~/.local/bin/check_battery
    sleep 60
done &
