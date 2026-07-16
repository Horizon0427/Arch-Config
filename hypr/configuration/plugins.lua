hl.config { plugin = { dynamic_cursors = {
    enabled = true,
    mode = "stretch",
    threshold = 2,

    stretch = {
        limit = 3000,
        activation = "quadratic",
        window = 100,
    },
    shake = {
        enabled = false,
    },

    hyprcursor = {
        nearest = 1,
        enabled = true,
        resolution = -1,
        fallback = "clientside",
    },
}}}
