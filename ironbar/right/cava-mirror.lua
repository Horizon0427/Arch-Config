local FRAME_PATH = (os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000")
    .. "/ironbar-cava/frame"
local COLORS_PATH = (os.getenv("HOME") or "/home/horizon")
    .. "/.config/ironbar/colors.css"
local PROFILE_PATH = "/sys/firmware/acpi/platform_profile"
local SOURCE_BANDS = 9
local DISPLAY_BANDS = 12
local ACTIVE_HEIGHT = 180
local EDGE_BUFFER = 24
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

    local function set_colour(cr, alpha)
        cr:set_source_rgba(state.red, state.green, state.blue, alpha)
    end

    local function scaled_points(points, origin_x, scale)
        local result = {}
        for index, point in ipairs(points) do
            result[index] = {
                x = origin_x - (origin_x - point.x) * scale,
                y = point.y,
            }
        end
        return result
    end

    local function trace_contour(cr, points)
        cr:move_to(points[1].x, points[1].y)
        for index = 2, #points do
            local previous = points[index - 1]
            local point = points[index]
            local middle_y = (previous.y + point.y) * 0.5
            cr:curve_to(
                previous.x,
                middle_y,
                point.x,
                middle_y,
                point.x,
                point.y
            )
        end
    end

    local function fill_fog(cr, points, origin_x, alpha)
        cr:new_path()
        trace_contour(cr, points)
        cr:line_to(origin_x, points[#points].y)
        cr:line_to(origin_x, points[1].y)
        cr:close_path()
        set_colour(cr, alpha)
        cr:fill()
    end

    local fog_layers = {
        { scale = 1.08, alpha = 0.004, pulse = 0.010 },
        { scale = 1.00, alpha = 0.006, pulse = 0.014 },
        { scale = 0.92, alpha = 0.009, pulse = 0.020 },
        { scale = 0.82, alpha = 0.013, pulse = 0.028 },
        { scale = 0.71, alpha = 0.017, pulse = 0.036 },
        { scale = 0.58, alpha = 0.023, pulse = 0.046 },
        { scale = 0.44, alpha = 0.030, pulse = 0.056 },
        { scale = 0.30, alpha = 0.037, pulse = 0.065 },
        { scale = 0.18, alpha = 0.045, pulse = 0.075 },
    }

    return function(cr, width, height)
        width = width or 36
        height = height or (ACTIVE_HEIGHT + 2 * EDGE_BUFFER)
        refresh_palette()

        local targets = read_targets()
        local origin_x = width - 5
        local max_length = math.max(8, origin_x - 3)
        local buffer = math.min(EDGE_BUFFER, math.max(0, (height - 1) * 0.25))
        local active_height = math.min(ACTIVE_HEIGHT, height - 2 * buffer)
        local active_top = (height - active_height) * 0.5
        local row_height = active_height / DISPLAY_BANDS
        local raw_energy = {}

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
            raw_energy[index] = (current / 7) ^ 0.78
        end

        local energies = {}
        local average_energy = 0
        local peak_energy = 0
        for index = 1, DISPLAY_BANDS do
            local previous = raw_energy[math.max(1, index - 1)]
            local current = raw_energy[index]
            local following = raw_energy[math.min(DISPLAY_BANDS, index + 1)]
            local energy = (previous + 2 * current + following) * 0.25
            energies[index] = energy
            average_energy = average_energy + energy
            if energy > peak_energy then
                peak_energy = energy
            end
        end
        average_energy = average_energy / DISPLAY_BANDS

        local base_width = 1.7
        local top_length = base_width
            + energies[1] * (max_length - base_width)
        local bottom_length = base_width
            + energies[DISPLAY_BANDS] * (max_length - base_width)
        local points = {
            { x = origin_x, y = 0.5 },
            {
                x = origin_x - top_length * 0.04,
                y = buffer * 0.32,
            },
            {
                x = origin_x - top_length * 0.18,
                y = buffer * 0.62,
            },
            {
                x = origin_x - top_length * 0.48,
                y = buffer * 0.86,
            },
        }
        for index = 1, DISPLAY_BANDS do
            local energy = energies[index]
            local length = base_width + energy * (max_length - base_width)
            points[#points + 1] = {
                x = origin_x - length,
                y = active_top + (index - 0.5) * row_height,
            }
        end
        for _, stop in ipairs({
            { position = 0.86, width = 0.48 },
            { position = 0.62, width = 0.18 },
            { position = 0.32, width = 0.04 },
        }) do
            points[#points + 1] = {
                x = origin_x - bottom_length * stop.width,
                y = height - buffer * stop.position,
            }
        end
        points[#points + 1] = { x = origin_x, y = height - 0.5 }

        local fog_activity = 0.68 * average_energy + 0.32 * peak_energy
        for _, layer in ipairs(fog_layers) do
            fill_fog(
                cr,
                scaled_points(points, origin_x, layer.scale),
                origin_x,
                layer.alpha + layer.pulse * fog_activity
            )
        end
    end
end

return new_renderer
