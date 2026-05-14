local colors = require("configuration.colors")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in     = 2.5,
        gaps_out    = 6,
        border_size = 3,
        col = {
            active_border   = { colors = { colors.primary, "rgba(ffffffff)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "scrolling",
        snap = {
            enabled        = true,
            window_gap     = 10,
            monitor_gap    = 10,
            border_overlap = true,
            respect_gaps   = true,
        },
    },

    decoration = {
        rounding           = 15,
        rounding_power     = 3,
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,
        shadow = {
            enabled      = false,
            range        = 2,
            render_power = 2,
            color        = colors.primary,
        },
        blur = {
            enabled           = true,
            size              = 7,
            passes            = 3,
            vibrancy          = 0.1696,
            new_optimizations = true,
            popups            = true,
            xray              = true,
        },
        glow = {
            enabled      = false,
            range        = 12,
            render_power = 3,
            color        = colors.primary,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    group = {
        groupbar = {
            middle_click_close = true,
            scrolling          = true,
            blur               = false,
        },
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})
