local config_dir = (os.getenv("HOME") or "/home/horizon")
    .. "/.config/ironbar/right/"
local new_mirrored_renderer = dofile(config_dir .. "cava-mirror.lua")

draw = new_mirrored_renderer("right")
return draw
