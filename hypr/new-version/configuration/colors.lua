-- 由 matugen 根据当前壁纸自动生成，请勿手动修改。
--
-- ── matugen 接入方式 ──────────────────────────────────────────
-- 1. 在 ~/.config/matugen/config.toml 中添加：
--
--    [templates.hyprland_colors]
--    input_path  = "~/.config/matugen/templates/hyprland_colors.lua"
--    output_path = "~/.config/hypr/new-version/configuration/colors.lua"
--
-- 2. 创建模板文件 ~/.config/matugen/templates/hyprland_colors.lua：
--
--    return {
--        primary   = "rgb({{colors.primary.default.hex_stripped}})",
--        secondary = "rgb({{colors.secondary.default.hex_stripped}})",
--        inactive  = "rgb({{colors.tertiary.default.hex_stripped}})",
--    }
--
-- 每次 matugen 运行（换壁纸）后，Hyprland 会自动热重载本文件。
-- ─────────────────────────────────────────────────────────────

return {
    primary   = "rgb(81d5ce)",
    secondary = "rgb(b0ccc9)",
    inactive  = "rgb(889391)",
}
