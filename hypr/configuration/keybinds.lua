local mainMod     = "SUPER"
local terminal    = "ghostty"
local fileManager = "thunar"
local menu        = "walker"

hl.config({
    binds = {
        scroll_event_delay = 150,
    },
})

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("flclash"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("~/.local/bin/wallpicker"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd([[command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit]]))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + X", hl.dsp.workspace.toggle_special("spotify"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_layout.sh"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_animation.sh"))

hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("~/.config/ironbar/scripts/ironbar-control.sh toggle"))
hl.bind(mainMod .. " + F2", hl.dsp.exec_cmd("~/.config/ironbar/scripts/ironbar-control.sh reload"))

hl.bind(mainMod .. " + ALT + L",   hl.dsp.exec_cmd("~/.config/hypr/scripts/smart_lock.sh"))
hl.bind(mainMod .. " + ALT + V",   hl.dsp.exec_cmd("copyq toggle"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))

local function focus_horizontal(direction, scrolling_direction)
    return function()
        local workspace = hl.get_active_workspace()

        if workspace and workspace.tiled_layout == "scrolling" then
            hl.dispatch(hl.dsp.layout("focus " .. scrolling_direction))
        else
            hl.dispatch(hl.dsp.focus({ direction = direction }))
        end
    end
end

hl.bind(mainMod .. " + left",  focus_horizontal("left",  "l"))
hl.bind(mainMod .. " + right", focus_horizontal("right", "r"))
hl.bind(mainMod .. " + H",     focus_horizontal("left",  "l"))
hl.bind(mainMod .. " + L",     focus_horizontal("right", "r"))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,       hl.dsp.focus({ workspace = i        }))
    hl.bind(mainMod .. " + ALT + " .. i, hl.dsp.window.move({ workspace = i  }))
end
hl.bind(mainMod .. " + 0",       hl.dsp.focus({ workspace = 10       }))
hl.bind(mainMod .. " + ALT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

local ZOOM_MIN  = 1.0
local ZOOM_MAX  = 6.0
local ZOOM_STEP = 2.0

local function set_cursor_zoom(factor)
    hl.config({
        cursor = {
            zoom_factor = math.max(ZOOM_MIN, math.min(ZOOM_MAX, factor)),
        },
    })
end

local function adjust_cursor_zoom(multiplier)
    set_cursor_zoom(hl.get_config("cursor.zoom_factor") * multiplier)
end

hl.bind(mainMod .. " + SHIFT + mouse_up", function()
    adjust_cursor_zoom(ZOOM_STEP)
end)

hl.bind(mainMod .. " + SHIFT + mouse_down", function()
    adjust_cursor_zoom(1 / ZOOM_STEP)
end)

hl.bind(mainMod .. " + SHIFT + Z", function()
    set_cursor_zoom(ZOOM_MIN)
end)

hl.bind(mainMod .. " + W",            hl.dsp.layout("colresize +conf"))
hl.bind(mainMod .. " + O",            hl.dsp.layout("fit all"))
hl.bind(mainMod .. " + ALT + O",      hl.dsp.layout("fit active"))
hl.bind(mainMod .. " + ALT + P",      hl.dsp.layout("promote"))
hl.bind(mainMod .. " + bracketleft",  hl.dsp.layout("colresize -0.1"))
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("colresize +0.1"))
hl.bind(mainMod .. " + comma",        hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + period",       hl.dsp.layout("swapcol r"))

hl.bind(mainMod .. " + SHIFT + E", hl.dsp.layout("expel"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.layout("consume"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.layout("consume_or_expel prev"))
hl.bind(mainMod .. " + M",         hl.dsp.layout("center"))

hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + N", hl.dsp.layout("rotatesplit"))

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ into_or_create_group = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ into_or_create_group = "r" }))
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ into_or_create_group = "u" }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ into_or_create_group = "d" }))
hl.bind(mainMod .. " + CTRL + O", hl.dsp.window.move({ out_of_group = true }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local el = { locked = true, repeating = true }
local l  = { locked = true }

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  el)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       el)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      el)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    el)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                   el)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                   el)
hl.bind("Print",                 hl.dsp.exec_cmd([[grim ~/Pictures/quickshot/quickshot_$(date +'%Y-%m-%d_%H-%M-%S').png]]), l)
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       l)
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   l)
