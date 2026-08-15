local FRAME_PATH = (os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000")
    .. "/ironbar-cava/frame"
local COLORS_PATH = (os.getenv("HOME") or "/home/horizon")
    .. "/.config/ironbar/colors.css"
local PROFILE_PATH = "/sys/firmware/acpi/platform_profile"
local SOURCE_BANDS = 9
local DISPLAY_BANDS = 12
local VISUAL_GAIN = 1.32
local ATTACK_RESPONSE = 0.74
local RELEASE_RESPONSE = 0.29

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function read_first_line(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local line = file:read("*l")
    file:close()
    return line
end

local function parse_colour(name, fallback)
    local file = io.open(COLORS_PATH, "r")
    if not file then
        return fallback
    end

    local hex = nil
    for line in file:lines() do
        local found_name, found_hex = string.match(
            line,
            "@define%-color%s+([%w_-]+)%s+#([%x]+)%s*;"
        )
        if found_name == name then
            hex = found_hex
            break
        end
    end
    file:close()

    if not hex or #hex ~= 6 then
        return fallback
    end

    return {
        tonumber(string.sub(hex, 1, 2), 16) / 255,
        tonumber(string.sub(hex, 3, 4), 16) / 255,
        tonumber(string.sub(hex, 5, 6), 16) / 255,
    }
end

local function new_renderer(channel)
    assert(channel == "left" or channel == "right", "invalid Cava channel")

    local state = {
        levels = {},
        red = 0.50,
        green = 0.84,
        blue = 0.81,
        last_palette_check = 0,
    }

    for index = 1, DISPLAY_BANDS do
        state.levels[index] = 0
    end

    local frame_offset = channel == "left" and 0 or 9

    local function read_targets()
        local line = read_first_line(FRAME_PATH)
        if not line then
            return nil
        end

        local frame = {}
        for value in string.gmatch(line, "(%d+)") do
            frame[#frame + 1] = clamp(tonumber(value) or 0, 0, 7)
        end
        if #frame ~= 18 then
            return nil
        end

        local source = {}
        for index = 1, SOURCE_BANDS do
            source[index] = frame[frame_offset + index]
        end

        local targets = {}
        for index = 1, DISPLAY_BANDS do
            local position = 1
                + (index - 1) * (SOURCE_BANDS - 1) / (DISPLAY_BANDS - 1)
            local lower = math.floor(position)
            local upper = math.min(lower + 1, SOURCE_BANDS)
            local fraction = position - lower
            targets[index] = source[lower] * (1 - fraction)
                + source[upper] * fraction
        end
        return targets
    end

    local function refresh_palette()
        local now = os.time()
        if now == state.last_palette_check then
            return
        end
        state.last_palette_check = now

        local profile = read_first_line(PROFILE_PATH) or "power-saver"
        local colour_name = "primary"
        local fallback = { 0.50, 0.84, 0.81 }

        if profile == "balanced" then
            colour_name = "tertiary"
            fallback = { 0.69, 0.79, 0.91 }
        elseif profile == "performance" then
            colour_name = "error"
            fallback = { 1.00, 0.71, 0.67 }
        end

        local colour = parse_colour(colour_name, fallback)
        state.red, state.green, state.blue = colour[1], colour[2], colour[3]
    end

    local function paint_dot(cr, x, y, radius, alpha)
        cr:set_source_rgba(state.red, state.green, state.blue, alpha)
        cr:arc(x, y, radius, 0, 2 * math.pi)
        cr:fill()
    end

    return function(cr, width, height)
        width = width or 36
        height = height or 180
        refresh_palette()

        local targets = read_targets()
        local origin_x = 8
        local max_length = math.max(8, width - origin_x - 3)
        local row_height = height / DISPLAY_BANDS

        for index = 1, DISPLAY_BANDS do
            local target = targets
                and clamp(targets[index] * VISUAL_GAIN, 0, 7)
                or 0
            local current = state.levels[index]
            local response = target > current
                and ATTACK_RESPONSE
                or RELEASE_RESPONSE
            current = current + (target - current) * response

            if current < 0.08 then
                current = 0
            end
            state.levels[index] = current

            if current > 0 then
                local energy = current / 7
                local y = (index - 0.5) * row_height
                local length = energy * max_length

                cr:set_source_rgba(
                    state.red,
                    state.green,
                    state.blue,
                    0.08 + 0.22 * energy
                )
                cr:set_line_width(0.65)
                cr:move_to(origin_x, y)
                cr:line_to(origin_x + length, y)
                cr:stroke()

                local dot_count = 7
                local lit_extent = energy * dot_count
                for dot = 0, dot_count - 1 do
                    local lit = clamp(lit_extent - dot, 0, 1)
                    if lit > 0.02 then
                        local x = origin_x
                            + dot * max_length / (dot_count - 1)
                        paint_dot(cr, x, y, 2.2, 0.045 * lit)
                        paint_dot(
                            cr,
                            x,
                            y,
                            0.72 + 0.20 * lit,
                            0.30 + 0.58 * lit
                        )
                    end
                end
            end
        end
    end
end

return new_renderer
