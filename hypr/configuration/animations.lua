hl.config({ animations = { enabled = true } })


hl.curve("easeOutQuint",   { type = "bezier", points = { {0.22, 1},   {0.36, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0},   {0.35, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0,    0},   {1,    1}   } })
hl.curve("quickSnap",      { type = "bezier", points = { {0.15, 0},   {0.1,  1}   } })
hl.curve("layerEase",      { type = "bezier", points = { {0.4,  0.0}, {0.2,  1.0} } })


hl.animation({ leaf = "windowsIn",   enabled = true, speed = 10, bezier = "easeOutQuint", style = "popin 60%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 10, bezier = "easeOutQuint", style = "gnomed"    })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 10, bezier = "easeOutQuint"                      })


hl.animation({ leaf = "border",      enabled = true, speed = 4,  bezier = "quickSnap"                   })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear",    style = "loop"   })


hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "layerEase" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 4, bezier = "layerEase" })


hl.animation({ leaf = "fadePopups", enabled = true, speed = 3, bezier = "layerEase" })


hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 7, bezier = "easeInOutCubic", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 7, bezier = "easeInOutCubic", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 7, bezier = "easeInOutCubic", style = "slidevert"     })


hl.animation({ leaf = "layersIn",  enabled = true, speed = 2, bezier = "layerEase", style = "popin 60%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 6, bezier = "layerEase", style = "popin 60%" })
