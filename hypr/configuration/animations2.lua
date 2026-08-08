hl.config({ animations = { enabled = true } })

local function spring(name, settle, zeta, mass)
    mass = mass or 1
    zeta = zeta or 1.0
    local omega0    = 6.0 / (zeta * settle)
    local stiffness = mass * omega0 * omega0
    local dampening = 2.0 * zeta * omega0 * mass
    hl.curve(name, { type = "spring", mass = mass, stiffness = stiffness, dampening = dampening })
end

spring("quietSpring",   0.6, 0.8)
spring("settleSpring",  0.5, 0.8)
spring("followSpring",  0.7, 0.8)
spring("glideSpring",   0.6, 0.8)

hl.curve("softFade",   { type = "bezier", points = { {0.37, 0},   {0.63, 1} } })
hl.curve("borderEase", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1} } })

hl.animation({ leaf = "windowsIn",   enabled = true, speed = 8.5, spring = "quietSpring",  style = "popin 90%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7.0, spring = "settleSpring", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6.5, spring = "followSpring" })

hl.animation({ leaf = "border",      enabled = true, speed = 5.0, bezier = "borderEase" })
hl.animation({ leaf = "borderangle", enabled = false })

hl.animation({ leaf = "fade",          enabled = true, speed = 4.5, bezier = "softFade" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 5.0, bezier = "softFade" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 5.5, bezier = "softFade" })
hl.animation({ leaf = "fadeSwitch",    enabled = true, speed = 4.5, bezier = "softFade" })
hl.animation({ leaf = "fadeShadow",    enabled = true, speed = 4.5, bezier = "softFade" })
hl.animation({ leaf = "fadeDim",       enabled = true, speed = 5.0, bezier = "softFade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 4.0, bezier = "softFade" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 4.0, bezier = "softFade" })
hl.animation({ leaf = "fadePopups",    enabled = true, speed = 3.0, bezier = "softFade" })

hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 9.5, spring = "glideSpring", style = "slidefade 12%" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 9.5, spring = "glideSpring", style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 9.5, spring = "glideSpring", style = "slidefadevert 14%" })

hl.animation({ leaf = "layersIn",  enabled = true, speed = 4.5, bezier = "softFade", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3.5, bezier = "softFade", style = "fade" })
