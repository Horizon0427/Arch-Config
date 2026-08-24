local plugins_disabled = os.getenv("HYPR_NO_PLUGINS") == "1"

if not plugins_disabled and hl.plugin.dynamic_cursors ~= nil then
    hl.config({
        plugin = {
            dynamic_cursors = {
                enabled = false,
                mode = "stretch",
                threshold = 2,
                stretch = {
                    limit = 3000,
                    activation = "quadratic",
                    window = 100,
                },
                shake = { enabled = false },
                hyprcursor = {
                    nearest = 1,
                    enabled = true,
                    resolution = -1,
                    fallback = "clientside",
                },
            },
        },
    })
end

if not plugins_disabled and hl.plugin.glasscope ~= nil then
    hl.config({
        binds = { scroll_event_delay = 50 },
        plugin = {
            glasscope = {
                radius = 130,
                zoom = 2.0,
                refraction = 1.0,
                dispersion = 0.7,
                bulge = 0.08,
                edge_width = 22.0,
                edge_strength = 1.25,
                motion_strength = 1.5,
                nearest = false,
            },
        },
    })
end

if not plugins_disabled and hl.plugin.hyglass ~= nil then
    hl.config({
        plugin = {
            hyglass = {
                enabled = true,
                geometry = {
                    corner_radius = -1,
                    depth_radius = 72.0,
                },
                optics = {
                    strength = 0.35,
                    refraction = 0.0,
                    edge_bulge = 0.55,
                    dispersion = 0.6,
                    roughness = 0.60,
                    tint = "rgba(0x08, 0x0c, 0x12, 0.04)",
                    brightness = 1.05,
                },
                effects = {
                    interior_warp = 0.0,
                    interior_motion = 0.0,
                    concavity = 0.0,
                    motion = 0.0,
                    highlight = 0.15,
                },
            },
        },
    })

    hl.window_rule({
        name = "hyglass-terminals",
        match = { class = "^(kitty|com\\.mitchellh\\.ghostty)$" },
        tag = "+hyglass",
        no_blur = true,
    })
end
