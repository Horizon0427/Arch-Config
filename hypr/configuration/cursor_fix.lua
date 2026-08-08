local LOGICAL  = 30
local PHYSICAL = 48
local FALLBACK = 28

local function setSizes(logical, physical)
    hl.env("HYPRCURSOR_SIZE", tostring(logical))
    hl.env("XCURSOR_SIZE", tostring(physical))
end

if os.getenv("HYPR_NO_PLUGINS") == "1" then
    setSizes(FALLBACK, FALLBACK)
    return
end

local so = os.getenv("HOME") .. "/.local/share/hypr/plugins/xwl-cursor-fix.so"
local f = io.open(so, "r")
if not f then
    setSizes(FALLBACK, FALLBACK)
    return
end
f:close()

hl.plugin.load(so)
setSizes(LOGICAL, PHYSICAL)
