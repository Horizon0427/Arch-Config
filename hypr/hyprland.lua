local script_path = debug.getinfo(1, "S").source:sub(2)
local config_dir  = script_path:match("(.+)/[^/]+$") or "."
package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

require("configuration.monitors")
require("configuration.env")
require("configuration.cursor_fix") -- must come after configuration.env
require("configuration.autostart")
require("configuration.appearance")
require("configuration.animations2")
require("configuration.scrolling")
require("configuration.input")
require("configuration.keybinds")
require("configuration.plugins") -- plugin config after bindings; guards tolerate cold start
require("configuration.rules")
