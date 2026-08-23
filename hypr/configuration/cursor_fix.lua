local LOGICAL  = 30
local PHYSICAL = 48
local FALLBACK = 28

local function setSizes(logical, physical)
    hl.env("HYPRCURSOR_SIZE", tostring(logical))
    hl.env("XCURSOR_SIZE", tostring(physical))
end

local function readAll(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local function compatibleBuild(infoPath)
    local metadata = readAll(infoPath)
    if not metadata then return false end

    local hyprland = metadata:match('"hyprland"%s*:%s*{(.-)}')
    if not hyprland then return false end
    local expectedAbi = hyprland:match('"abi"%s*:%s*"([^"]+)"')
    local expectedCommit = hyprland:match('"commit"%s*:%s*"([0-9a-f]+)"')
    if not expectedAbi or not expectedCommit then return false end

    local process = io.popen("Hyprland --version 2>/dev/null", "r")
    if not process then return false end
    local current = process:read("*a")
    process:close()
    return current:find("commit " .. expectedCommit, 1, true) ~= nil
        and current:find("Version ABI string: " .. expectedAbi, 1, true) ~= nil
end

if os.getenv("HYPR_NO_PLUGINS") == "1" then
    setSizes(FALLBACK, FALLBACK)
    return
end

local root = os.getenv("HOME") .. "/.local"
local so = root .. "/lib/hyprland-plugins/xwl-cursor-fix/xwl-cursor-fix.so"
local info = root .. "/share/hyprland-plugins/xwl-cursor-fix/build-info.json"
local f = io.open(so, "r")
if not f then
    setSizes(FALLBACK, FALLBACK)
    return
end
f:close()

local ok, compatible = pcall(compatibleBuild, info)
if not ok or not compatible then
    setSizes(FALLBACK, FALLBACK)
    return
end

hl.plugin.load(so)
setSizes(LOGICAL, PHYSICAL)
