hl.config({
    plugin = {
        ["dynamic-cursors"] = {
            enabled   = true,
            mode      = "stretch",
            threshold = 2,
            stretch = {
                limit        = 2500,
                ["function"] = "quadratic",
            },
            shake = {
                enabled = false,
            },
        },
    },
})
