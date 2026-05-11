-- ══════════════════════════════════════════
-- 窗口规则
-- ══════════════════════════════════════════
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true,
              float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "float-waypaper",
    match = { class = "^(waypaper)$" },
    float = true, center = true,
})

hl.window_rule({
    name  = "float-copyq",
    match = { class = "^(com.github.hluk.copyq)$" },
    float = true, center = true,
})

hl.window_rule({
    name  = "float-screenshot",
    match = { class = "be.alexandervanhee.gradia" },
    float = true, center = true,
})

hl.window_rule({
    name  = "screenshot-save",
    match = { class = "^(xdg-desktop-portal-gtk)" },
    float = true, center = true, size = "900 600",
})

hl.window_rule({
    name  = "transparent-terminal",
    match = { class = "com.mitchellh.ghostty" },
    opacity = "1.0 override 0.5 override",
})

hl.window_rule({
    name  = "prelock-fullscreen",
    match = { class = "^(Smooth_Prelock)$" },
    fullscreen = true,
})

hl.window_rule({
    name  = "longshot-overlay-rules",
    match = { class = "^(longshot_overlay)$" },
    float            = true,
    border_size      = 0,
    rounding         = 0,
    no_blur          = true,
    no_shadow        = true,
    no_initial_focus = true,
    no_focus         = true,
    pin              = true,
    suppress_event   = "activatefocus maximize fullscreen",
})

hl.window_rule({
    name  = "wall-paper-picker",
    match = { class = "^(wallpicker)$" },
    fullscreen   = true,
    center       = true,
    stay_focused = true,
    animation    = "popin 0",
})

hl.window_rule({
    name  = "spotify",
    match = { class = "(?i)^(spotify)$" },
    workspace = "special:spotify",
})

-- ══════════════════════════════════════════
-- Layer 规则
-- ══════════════════════════════════════════
hl.layer_rule({
    name  = "wlogout_blur",
    match = { namespace = "^(logout_dialog)$" },
    blur = true, ignore_alpha = 0.0,
})

hl.layer_rule({
    name  = "slurp-selection-noanim",
    match = { namespace = "^(selection)$" },
    no_anim = true,
})

hl.layer_rule({
    name  = "Liquid_Glass_Waybar",
    match = { namespace = "^(waybar)$" },
    blur = true, ignore_alpha = 0.25,
})
