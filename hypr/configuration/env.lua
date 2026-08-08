hl.env("XCURSOR_THEME",    "BreezeX-RosePine-Linux")
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")

-- NOTE: XCURSOR_SIZE / HYPRCURSOR_SIZE are deliberately NOT set here.
-- configuration/cursor_fix.lua owns them, because the correct value depends on whether
-- the xwl-cursor-fix plugin actually loaded (48 with it, 28 without it). Setting the
-- same variable from two places has no defined precedence in Hyprland's env list.

hl.env("QT_IM_MODULE",     "fcitx")
hl.env("XMODIFIERS",       "@im=fcitx")
hl.env("LANG",             "zh_CN.UTF-8")
hl.env("LANGUAGE",         "zh_CN:en_US")
hl.env("GSK_RENDERER",     "gl")
hl.env("GDK_DISABLE",      "vulkan")
