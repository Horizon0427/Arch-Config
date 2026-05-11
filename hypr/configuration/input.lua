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

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
