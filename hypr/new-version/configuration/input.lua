hl.config({
    input = {
        kb_layout     = "us",
        kb_variant    = "",
        kb_model      = "",
        kb_options    = "",
        kb_rules      = "",
        accel_profile = "flat",
        follow_mouse  = 1,
        repeat_delay  = 250,
        repeat_rate   = 35,
        sensitivity   = 1.0,
        touchpad = {
            natural_scroll          = true,
            disable_while_typing    = true,
            middle_button_emulation = true,
        },
    },
})

-- 三指横扫切换工作区
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 双指捏合实时缩放（0.55 新增）
-- action "zoom" 运行时报错，语法待官方 wiki 确认后再启用
-- hl.gesture({ fingers = 2, direction = "pinch", action = "zoom" })

-- [待确认] 三指纵扫驱动 scrolling 布局滚动（0.55 新增，语法待核实）
-- hl.gesture({ fingers = 3, direction = "vertical", action = "scrolling:scroll_move" })

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
