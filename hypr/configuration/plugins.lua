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
    local glasscope_enabled = true

    hl.config({
        binds = { scroll_event_delay = 50 },
        plugin = {
            glasscope = {
                enabled = glasscope_enabled,
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
    local hyglass_enabled = true

    local hyglass_preset_name = "daily"

    local hyglass_presets = {
        custom = {
            geometry = {
                corner_radius = -1,
                depth_radius = 50,
            },
            optics = {
                strength = 0.50,
                refraction = 20.0,
                edge_bulge = 1.0,
                dispersion = 4.0,
                roughness = 1.0,
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

        subtle = {
            geometry = { corner_radius = -1, depth_radius = 72.0 },
            optics = {
                strength = 0.35, refraction = 0.0, edge_bulge = 0.55,
                dispersion = 0.6, roughness = 0.60,
                tint = "rgba(0x08, 0x0c, 0x12, 0.04)", brightness = 1.05,
            },
            effects = {
                interior_warp = 0.0, interior_motion = 0.0,
                concavity = 0.0, motion = 0.0, highlight = 0.15,
            },
        },

        daily = {
            geometry = { corner_radius = -1, depth_radius = 104.0 },
            optics = {
                strength = 0.64, refraction = 0.0, edge_bulge = 0.86,
                dispersion = 1.35, roughness = 0.76,
                tint = "rgba(0x08, 0x0c, 0x12, 0.03)", brightness = 1.12,
            },
            effects = {
                interior_warp = 0.0, interior_motion = 0.0,
                concavity = 0.10, motion = 0.0, highlight = 0.28,
            },
        },

        fidelity = {
            geometry = { corner_radius = -1, depth_radius = 0.0 },
            optics = {
                strength = 0.80, refraction = 0.0, edge_bulge = 1.0,
                dispersion = 2.0, roughness = 0.85,
                tint = "rgba(0x00, 0x00, 0x00, 0.0)", brightness = 1.20,
            },
            effects = {
                interior_warp = 0.0, interior_motion = 0.0,
                concavity = 0.0, motion = 0.0, highlight = 0.0,
            },
        },

        prismatic = {
            geometry = { corner_radius = -1, depth_radius = 120.0 },
            optics = {
                strength = 1.0, refraction = 18.0, edge_bulge = 1.20,
                dispersion = 4.0, roughness = 0.55,
                tint = "rgba(0x08, 0x10, 0x1c, 0.08)", brightness = 1.08,
            },
            effects = {
                interior_warp = 0.0, interior_motion = 0.0,
                concavity = 0.35, motion = 0.75, highlight = 0.90,
            },
        },

        showcase = {
            geometry = { corner_radius = -1, depth_radius = 160.0 },
            optics = {
                strength = 1.4, refraction = 64.0, edge_bulge = 1.25,
                dispersion = 5.5, roughness = 0.48,
                tint = "rgba(0x08, 0x0b, 0x10, 0.02)", brightness = 1.18,
            },
            effects = {
                interior_warp = 64.0, interior_motion = 1.45,
                concavity = 0.90, motion = 1.55, highlight = 1.15,
            },
        },
    }

    local hyglass_preset = assert(
        hyglass_presets[hyglass_preset_name],
        "unknown HyGlass preset: " .. tostring(hyglass_preset_name)
    )

    hl.config({
        plugin = {
            hyglass = {
                enabled = hyglass_enabled,
                geometry = hyglass_preset.geometry,
                optics = hyglass_preset.optics,
                effects = hyglass_preset.effects,
            },
        },
    })

    hl.window_rule({
        name = "hyglass-terminals",
        match = { class = "^(com\\.mitchellh\\.ghostty)$" },
        tag = "+hyglass",
        no_blur = true,
    })
end
