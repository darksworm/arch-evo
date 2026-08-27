-- Hyprland config — arch-evo

local home = os.getenv("HOME")

-- ── Appearance ──────────────────────────────────────────────
hl.config({
    general = {
        border_size = 2,
        gaps_in = 4,
        gaps_out = 4,

        -- cyberdream palette
        col = {
            active_border = "rgba(5ea1ff80)",
            inactive_border = "rgba(3c404840)",
        },

        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,

        active_opacity = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled = true,
            range = 8,
            render_power = 2,
            color = "rgba(5ea1ff20)",
            offset = { 0, 2 },
        },

        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("neon",     { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })
hl.curve("electric", { type = "bezier", points = { {0.87, 0},   {0.13, 1} } })
hl.curve("smooth",   { type = "bezier", points = { {0.23, 1},   {0.32, 1} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "smooth",   style = "slide" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3, bezier = "electric", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "electric", style = "popin 90%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2, bezier = "neon" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 2, bezier = "smooth" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 2, bezier = "electric" })
hl.animation({ leaf = "border",     enabled = true, speed = 3, bezier = "neon" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smooth",   style = "slide" })

-- ── Input ────────────────────────────────────────────────────
hl.config({
    input = {
        kb_layout = "lv",
        repeat_rate = 50,
        repeat_delay = 300,

        natural_scroll = true,
        accel_profile = "adaptive",

        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7,
        },

        follow_mouse = 1,
    },
})

-- ── Keyball44 Trackball ──────────────────────────────────────
hl.device({
    name = "yowkees-keyball44-mouse",
    scroll_factor = 0.3,
})

-- ── TrackPoint ───────────────────────────────────────────────
-- Middle button hold + nub movement = scroll
-- Verify name with: hyprctl devices
hl.device({
    name = "tpps/2-elan-trackpoint",
    scroll_method = "on_button_down",
    scroll_button = 274,
    scroll_factor = 0.7,
})

-- ── Monitor ─────────────────────────────────────────────────
-- machine-local monitor config; skip if absent, but fail loudly if broken
local monitorsLua = home .. "/.config/hypr/monitors.lua"
if io.open(monitorsLua) then dofile(monitorsLua) end
-- Catch-all AFTER sourced config — ensures laptop screen is never left unconfigured
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.workspace_rule({ workspace = "1", default = true })

-- ── Environment ─────────────────────────────────────────────
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("NO_AT_BRIDGE", "1")
hl.env("PATH", home .. "/.local/bin:" .. home .. "/.local/share/mise/shims:" .. os.getenv("PATH"))
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
hl.env("SSH_ASKPASS", home .. "/.local/bin/ssh-askpass-pass")
hl.env("SSH_ASKPASS_REQUIRE", "force")
hl.env("JAVA_HOME", home .. "/.local/share/mise/installs/java/21.0.2")

-- ── Misc ───────────────────────────────────────────────────
hl.config({
    misc = {
        vrr = 1,
        -- No built-in anime/logo wallpaper flashing before awww paints on hotplug.
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },
    debug = {
        disable_logs = false,
    },
})

-- ── Autostart ───────────────────────────────────────────────
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon && (awww restore || awww img ~/.local/share/wallpapers/egg-dali.jpg --transition-type none)")
    hl.exec_cmd("waybar")
    hl.exec_cmd("sleep 2 && pypr")
    hl.exec_cmd("dunst")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("~/.local/bin/sunset-control daemon")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("~/.config/hypr/scripts/monitor-hotplug")
    hl.exec_cmd("sh -c 'while true; do ~/.local/bin/check_battery; sleep 60; done'")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK SSH_ASKPASS SSH_ASKPASS_REQUIRE")
    hl.exec_cmd("foot --app-id foot-scratch -T foot-scratch")
end)

-- ── Window Rules ────────────────────────────────────────────
hl.window_rule({ match = { class = "zen-browser" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "pavucontrol" }, float = true })

-- hyper scratchpads — pyprland manages position/size, but needs float on
hl.window_rule({ match = { class = "[Ss]lack" },      float = true })
hl.window_rule({ match = { class = "vesktop" },       float = true })
hl.window_rule({ match = { class = "spotify" },       float = true })
hl.window_rule({ match = { class = "linear-linux" },  float = true })

-- terminal workspace — foot always lives here
hl.window_rule({ match = { class = "foot-scratch" }, workspace = "1 silent" })

-- ── Keybindings ─────────────────────────────────────────────
local mod = "SUPER"
local hyper = "CTRL + ALT + SUPER"

-- launch
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("fuzzel"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("cliphist list | fuzzel -d | cliphist decode | wl-copy"))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mod .. " + F", hl.dsp.exec_cmd("~/.local/bin/fanmode"))

-- close window
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())

-- named workspaces
hl.bind(mod .. " + grave",           hl.dsp.focus({ workspace = 1 }))
hl.bind(mod .. " + SHIFT + grave",   hl.dsp.window.move({ workspace = 1, follow = true }))
hl.bind(mod .. " + 1",               hl.dsp.focus({ workspace = 2 }))
hl.bind(mod .. " + SHIFT + 1",       hl.dsp.window.move({ workspace = 2, follow = true }))
hl.bind(mod .. " + 2",               hl.dsp.focus({ workspace = 3 }))
hl.bind(mod .. " + SHIFT + 2",       hl.dsp.window.move({ workspace = 3, follow = true }))
hl.bind(mod .. " + 3",               hl.dsp.focus({ workspace = 4 }))
hl.bind(mod .. " + SHIFT + 3",       hl.dsp.window.move({ workspace = 4, follow = true }))

-- hyper scratchpads — pyprland handles launch + hide/show
hl.bind(hyper .. " + S", hl.dsp.exec_cmd("pypr-toggle slack"))
hl.bind(hyper .. " + D", hl.dsp.exec_cmd("pypr-toggle discord"))
hl.bind(hyper .. " + M", hl.dsp.exec_cmd("pypr-toggle spotify"))
hl.bind(hyper .. " + L", hl.dsp.exec_cmd("pypr-toggle linear"))

-- focus
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))

-- master area
hl.bind(mod .. " + SHIFT + H", hl.dsp.layout("splitratio -0.05"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.layout("splitratio +0.05"))
hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- layout
hl.bind(mod .. " + T", hl.dsp.layout("setlayout dwindle"))
hl.bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + SHIFT + Z", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + space", hl.dsp.window.float())

-- monitor focus
hl.bind(mod .. " + period", hl.dsp.focus({ monitor = "+1" }))
hl.bind(mod .. " + comma",  hl.dsp.focus({ monitor = "-1" }))
hl.bind(mod .. " + SHIFT + greater", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mod .. " + SHIFT + less",    hl.dsp.window.move({ monitor = "-1" }))

-- screenshots & lock
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("screenshot region"))
hl.bind(mod .. " + F11", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-monitor"))
hl.bind(mod .. " + F12", hl.dsp.exec_cmd("~/.local/bin/lock"))
hl.bind(mod .. " + CTRL + Q", hl.dsp.exec_cmd("~/.local/bin/lock"))

-- media keys
hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd("volume-control up"),      { locked = true })
hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd("volume-control down"),    { locked = true })
hl.bind("XF86AudioMute",          hl.dsp.exec_cmd("volume-control mute"),    { locked = true })
hl.bind("XF86AudioPlay",          hl.dsp.exec_cmd("playerctl play-pause"),   { locked = true })
hl.bind("XF86AudioPause",         hl.dsp.exec_cmd("playerctl play-pause"),   { locked = true })
hl.bind("XF86AudioNext",          hl.dsp.exec_cmd("playerctl next"),         { locked = true })
hl.bind("XF86AudioPrev",          hl.dsp.exec_cmd("playerctl previous"),     { locked = true })
hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd("backlight-control up"),   { locked = true })
hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd("backlight-control down"), { locked = true })

-- workspaces (5-9)
for i = 5, 9 do
    hl.bind(mod .. " + " .. i,            hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,    hl.dsp.window.move({ workspace = i, follow = true }))
end

-- quit
hl.bind(mod .. " + SHIFT + CTRL + Q", hl.dsp.exit())

-- mouse bindings
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
