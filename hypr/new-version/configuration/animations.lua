hl.config({ animations = { enabled = true } })

-- ── Bezier 曲线 ───────────────────────────────────────────────
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.22, 1},   {0.36, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0},   {0.35, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0,    0},   {1,    1}   } })
hl.curve("quickSnap",      { type = "bezier", points = { {0.15, 0},   {0.1,  1}   } })
hl.curve("layerEase",      { type = "bezier", points = { {0.4,  0.0}, {0.2,  1.0} } })

-- ── Spring 物理曲线（Lua 格式独有，hyprlang 无法使用）─────────
-- stiffness ↑ = 更快、更弹；dampening ↑ = 弹跳更少、更阻尼
hl.curve("springy",       { type = "spring", mass = 1, stiffness = 120, dampening = 14 })
hl.curve("springySubtle", { type = "spring", mass = 1, stiffness = 70,  dampening = 12 })

-- ── 窗口动画 ──────────────────────────────────────────────────
hl.animation({ leaf = "windowsIn",   enabled = true,  speed = 7,  bezier = "easeOutQuint",   style = "popin 50%" })
hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 7,  bezier = "easeOutQuint",   style = "gnomed"    })
hl.animation({ leaf = "windowsMove", enabled = true,  speed = 6,  spring = "springy"                             })

-- ── 边框动画 ──────────────────────────────────────────────────
hl.animation({ leaf = "border",      enabled = true,  speed = 4,  bezier = "quickSnap"                      })
hl.animation({ leaf = "borderangle", enabled = true,  speed = 30, bezier = "linear",    style = "loop"      })

-- ── 淡入淡出 ──────────────────────────────────────────────────
hl.animation({ leaf = "fade",       enabled = true,  speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeIn",     enabled = true,  speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeOut",    enabled = true,  speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeSwitch", enabled = true,  speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeShadow", enabled = true,  speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeDim",    enabled = true,  speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadePopups", enabled = false, speed = 4, bezier = "layerEase" })

-- ── 工作区切换 ────────────────────────────────────────────────
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 5, spring = "springySubtle", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 5, spring = "springySubtle", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, spring = "springySubtle", style = "slidevert"     })

-- ── Layer 动画 ────────────────────────────────────────────────
hl.animation({ leaf = "layersIn",  enabled = true, speed = 4, bezier = "layerEase", style = "popin 50%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "layerEase", style = "popin 50%" })
