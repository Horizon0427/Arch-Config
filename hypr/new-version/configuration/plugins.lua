hl.config({
    plugin = {
        ["dynamic-cursors"] = {
            enabled   = true,
            mode      = "stretch",
            threshold = 2,
            stretch = {
                limit        = 2500,
                ["function"] = "quadratic",  -- "function" 是 Lua 关键字，必须加方括号引号
            },
            shake = {
                enabled = false,
            },
        },
    },
})
