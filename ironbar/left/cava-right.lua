local config_dir = (os.getenv("HOME") or "/home/horizon")
    .. "/.config/ironbar/left/"
local new_renderer = dofile(config_dir .. "cava-rail.lua")

draw = new_renderer("right")
return draw
