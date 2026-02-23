/* DWL config.h — arch-evo
 * Keybindings mapped from aerospace.toml + sxhkdrc
 * Colors from cyberdream palette
 */

/* appearance */
static const int sloppyfocus               = 1;
static const int bypass_surface_visibility  = 0;
static const unsigned int borderpx         = 2;
static const float rootcolor[]             = COLOR(0x16181aff);
static const float bordercolor[]           = COLOR(0x3c4048ff);
static const float focuscolor[]            = COLOR(0x5ea1ffff);
static const float urgentcolor[]           = COLOR(0xff6e5eff);

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
    /* app_id         title       tags mask  isfloating  monitor */
    { "brave-browser", NULL,      1 << 0,    0,          -1 },
    { "discord",       NULL,      1 << 3,    0,          -1 },
    { "Spotify",       NULL,      1 << 4,    0,          -1 },
    { "slack",         NULL,      1 << 5,    0,          -1 },
    { "pavucontrol",   NULL,      0,         1,          -1 },
};

/* layout(s) */
static const Layout layouts[] = {
    /* symbol     arrange function */
    { "[]=",      tile },
    { "><>",      NULL },    /* no layout function means floating behavior */
    { "[M]",      monocle },
};

/* monitors */
static const MonitorRule monrules[] = {
    /* name  mfact  nmaster  scale  layout  rotate/reflect  x  y */
    { NULL,  0.55f, 1,       1,     &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, -1, -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
    .layout = "lv",
};

static const int repeat_rate = 50;
static const int repeat_delay = 300;

/* trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 1;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

/* Autostart — handled externally by autostart.sh */

#define MODKEY WLR_MODIFIER_ALT
#define TAGKEYS(KEY,SKEY,TAG) \
    { MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
    { MODKEY|WLR_MODIFIER_CTRL, KEY,            toggleview,      {.ui = 1 << TAG} }, \
    { MODKEY|WLR_MODIFIER_SHIFT, SKEY,          tag,             {.ui = 1 << TAG} }, \
    { MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, SKEY, toggletag, {.ui = 1 << TAG} }

/* commands */
static const char *termcmd[]     = { "foot", NULL };
static const char *menucmd[]     = { "bemenu-run", "-i", "--fn", "monospace 12",
    "--tb", "#16181a", "--tf", "#5ea1ff",
    "--fb", "#16181a", "--ff", "#ffffff",
    "--nb", "#16181a", "--nf", "#ffffff",
    "--hb", "#5ea1ff", "--hf", "#16181a",
    "--sb", "#5ea1ff", "--sf", "#16181a",
    NULL };
static const char *browsercmd[]  = { "brave", NULL };
static const char *screenshot[]  = { "sh", "-c", "grim -g \"$(slurp)\" - | wl-copy", NULL };
static const char *lockcmd[]     = { "swaylock", NULL };

/* volume commands (using wob pipe) */
static const char *vol_up[]   = { "sh", "-c", "pamixer -i 5 && pamixer --get-volume > /tmp/wob.sock", NULL };
static const char *vol_down[] = { "sh", "-c", "pamixer -d 5 && pamixer --get-volume > /tmp/wob.sock", NULL };
static const char *vol_mute[] = { "sh", "-c", "pamixer -t && (pamixer --get-mute && echo 0 || pamixer --get-volume) > /tmp/wob.sock", NULL };

/* brightness commands */
static const char *bright_up[]   = { "sh", "-c", "brightnessctl set +5% && brightnessctl -m | cut -d, -f4 | tr -d '%' > /tmp/wob.sock", NULL };
static const char *bright_down[] = { "sh", "-c", "brightnessctl set 5%- && brightnessctl -m | cut -d, -f4 | tr -d '%' > /tmp/wob.sock", NULL };

/* media commands */
static const char *media_play[] = { "playerctl", "play-pause", NULL };
static const char *media_next[] = { "playerctl", "next", NULL };
static const char *media_prev[] = { "playerctl", "previous", NULL };

static const Key keys[] = {
    /* modifier                  key                 function        argument */
    { MODKEY,                    XKB_KEY_Return,     spawn,          {.v = termcmd} },
    { MODKEY,                    XKB_KEY_d,          spawn,          {.v = menucmd} },
    { MODKEY,                    XKB_KEY_c,          spawn,          {.v = browsercmd} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Q,         killclient,     {0} },

    /* focus */
    { MODKEY,                    XKB_KEY_h,          focusdir,       {.ui = 0} },  /* left */
    { MODKEY,                    XKB_KEY_l,          focusdir,       {.ui = 1} },  /* right */
    { MODKEY,                    XKB_KEY_k,          focusdir,       {.ui = 2} },  /* up */
    { MODKEY,                    XKB_KEY_j,          focusdir,       {.ui = 3} },  /* down */

    /* move window — fallback to stack operations */
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_H,         incnmaster,     {.i = +1} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_L,         incnmaster,     {.i = -1} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_K,         zoom,           {0} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_J,         zoom,           {0} },

    /* layout */
    { MODKEY,                    XKB_KEY_t,          setlayout,      {.v = &layouts[0]} },  /* tile */
    { MODKEY,                    XKB_KEY_f,          setlayout,      {.v = &layouts[1]} },  /* float */
    { MODKEY,                    XKB_KEY_m,          setlayout,      {.v = &layouts[2]} },  /* monocle */
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_Z,         togglefullscreen, {0} },
    { MODKEY,                    XKB_KEY_space,      togglefloating, {0} },

    /* master area */
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_minus,     setmfact,       {.f = -0.05f} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_equal,     setmfact,       {.f = +0.05f} },

    /* view all tags */
    { MODKEY,                    XKB_KEY_0,          view,           {.ui = ~0} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_parenright, tag,           {.ui = ~0} },

    /* monitor focus */
    { MODKEY,                    XKB_KEY_period,     focusmon,       {.i = WLR_DIRECTION_RIGHT} },
    { MODKEY,                    XKB_KEY_comma,      focusmon,       {.i = WLR_DIRECTION_LEFT} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_greater,   tagmon,         {.i = WLR_DIRECTION_RIGHT} },
    { MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_less,      tagmon,         {.i = WLR_DIRECTION_LEFT} },

    /* screenshots & lock */
    { WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_S, spawn,      {.v = screenshot} },
    { MODKEY,                    XKB_KEY_F12,        spawn,          {.v = lockcmd} },

    /* media keys */
    { 0, XKB_KEY_XF86AudioRaiseVolume,  spawn, {.v = vol_up} },
    { 0, XKB_KEY_XF86AudioLowerVolume,  spawn, {.v = vol_down} },
    { 0, XKB_KEY_XF86AudioMute,         spawn, {.v = vol_mute} },
    { 0, XKB_KEY_XF86AudioPlay,         spawn, {.v = media_play} },
    { 0, XKB_KEY_XF86AudioPause,        spawn, {.v = media_play} },
    { 0, XKB_KEY_XF86AudioNext,         spawn, {.v = media_next} },
    { 0, XKB_KEY_XF86AudioPrev,         spawn, {.v = media_prev} },
    { 0, XKB_KEY_XF86MonBrightnessUp,   spawn, {.v = bright_up} },
    { 0, XKB_KEY_XF86MonBrightnessDown, spawn, {.v = bright_down} },

    /* tags */
    TAGKEYS(XKB_KEY_1, XKB_KEY_exclam,      0),
    TAGKEYS(XKB_KEY_2, XKB_KEY_at,           1),
    TAGKEYS(XKB_KEY_3, XKB_KEY_numbersign,   2),
    TAGKEYS(XKB_KEY_4, XKB_KEY_dollar,       3),
    TAGKEYS(XKB_KEY_5, XKB_KEY_percent,      4),
    TAGKEYS(XKB_KEY_6, XKB_KEY_asciicircum,  5),
    TAGKEYS(XKB_KEY_7, XKB_KEY_ampersand,    6),
    TAGKEYS(XKB_KEY_8, XKB_KEY_asterisk,     7),
    TAGKEYS(XKB_KEY_9, XKB_KEY_parenleft,    8),

    /* quit */
    { MODKEY|WLR_MODIFIER_SHIFT|WLR_MODIFIER_CTRL, XKB_KEY_Q, quit, {0} },
};

static const Button buttons[] = {
    { MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
    { MODKEY, BTN_MIDDLE, togglefloating, {0} },
    { MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
