if os.getenv("HYPR_NO_PLUGINS") == "1" or hl.plugin.glasscope == nil then
    return
end

hl.config({
    binds = {
        scroll_event_delay = 50,
    },
})

local defaults = {
    radius = 130,
    zoom = 2.0,
    refraction = 1.0,
    dispersion = 0.7,
    bulge = 0.08,
    edge_width = 22.0,
    edge_strength = 1.25,
    motion_strength = 1.5,
    nearest = false,
}

local function apply_defaults()
    hl.config({
        plugin = {
            glasscope = defaults,
        },
    })
end

local function invoke_adjustment(name, delta)
    local glasscope = hl.plugin.glasscope
    if glasscope ~= nil and glasscope[name] ~= nil then
        glasscope[name](delta)
    end
end

local bind_options = { description = "Glasscope liquid lens" }

hl.bind("SUPER + SHIFT + A", function()
    if hl.plugin.glasscope ~= nil then
        hl.plugin.glasscope.toggle()
    end
end, bind_options)

hl.bind("SUPER + ALT + mouse_up", function()
    invoke_adjustment("adjust_zoom", 0.2)
end, bind_options)

hl.bind("SUPER + ALT + mouse_down", function()
    invoke_adjustment("adjust_zoom", -0.2)
end, bind_options)

-- The Legion Fn key is handled below XKB and is not available as a Hyprland
-- modifier. ALT + SHIFT is the nearest free chord; SUPER + SHIFT + wheel is
-- already used by the compositor-wide cursor zoom.
hl.bind("SUPER + ALT + SHIFT + mouse_up", function()
    invoke_adjustment("adjust_radius", 16)
end, bind_options)

hl.bind("SUPER + ALT + SHIFT + mouse_down", function()
    invoke_adjustment("adjust_radius", -16)
end, bind_options)

hl.bind("SUPER + CTRL + mouse_up", function()
    invoke_adjustment("adjust_edge_width", 2.0)
end, bind_options)

hl.bind("SUPER + CTRL + mouse_down", function()
    invoke_adjustment("adjust_edge_width", -2.0)
end, bind_options)

apply_defaults()
