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
        dispersion_red = 0.69,
        dispersion_green = 0.79,
        dispersion_blue = 0.91,
        fringe_red = 1.00,
        fringe_green = 0.71,
        fringe_blue = 0.67,
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
        local dispersion_name = "tertiary"
        local fringe_name = "error"
        local fallback = { 0.50, 0.84, 0.81 }
        local dispersion_fallback = { 0.69, 0.79, 0.91 }
        local fringe_fallback = { 1.00, 0.71, 0.67 }

        if profile == "balanced" then
            colour_name = "tertiary"
            dispersion_name = "primary"
            fallback = { 0.69, 0.79, 0.91 }
            dispersion_fallback = { 0.50, 0.84, 0.81 }
        elseif profile == "performance" then
            colour_name = "error"
            dispersion_name = "tertiary"
            fringe_name = "primary"
            fallback = { 1.00, 0.71, 0.67 }
            dispersion_fallback = { 0.69, 0.79, 0.91 }
            fringe_fallback = { 0.50, 0.84, 0.81 }
        end

        local colour = parse_colour(colour_name, fallback)
        local dispersion = parse_colour(
            dispersion_name,
            dispersion_fallback
        )
        local fringe = parse_colour(fringe_name, fringe_fallback)
        state.red, state.green, state.blue = colour[1], colour[2], colour[3]
        state.dispersion_red = dispersion[1]
        state.dispersion_green = dispersion[2]
        state.dispersion_blue = dispersion[3]
        state.fringe_red = fringe[1]
        state.fringe_green = fringe[2]
        state.fringe_blue = fringe[3]
    end

    local function set_colour(cr, alpha)
        cr:set_source_rgba(state.red, state.green, state.blue, alpha)
    end

    local function set_dispersion(cr, alpha)
        cr:set_source_rgba(
            state.dispersion_red,
            state.dispersion_green,
            state.dispersion_blue,
            alpha
        )
    end

    local function set_fringe(cr, alpha)
        cr:set_source_rgba(
            state.fringe_red,
            state.fringe_green,
            state.fringe_blue,
            alpha
        )
    end

    local function set_mix(cr, amount, alpha)
        local inverse = 1 - amount
        cr:set_source_rgba(
            state.red * inverse + state.dispersion_red * amount,
            state.green * inverse + state.dispersion_green * amount,
            state.blue * inverse + state.dispersion_blue * amount,
            alpha
        )
    end

    local function paint_beam(cr, origin_x, y, length, energy)
        local segments = 5
        for segment = 0, segments - 1 do
            local proximity = 1 - segment / segments
            local dispersion = segment / (segments - 1)
            local right_x = origin_x - length * segment / segments
            local left_x = origin_x - length * (segment + 1) / segments
            local alpha = (0.035 + 0.19 * energy) * proximity * proximity

            set_mix(cr, dispersion * 0.82, alpha)
            cr:set_line_width(0.48 + 0.28 * proximity)
            cr:move_to(left_x, y)
            cr:line_to(right_x, y)
            cr:stroke()

            set_dispersion(cr, alpha * (0.28 + 0.42 * dispersion))
            cr:set_line_width(0.32)
            cr:move_to(left_x, y - 0.58)
            cr:line_to(right_x, y - 0.58)
            cr:stroke()

            set_fringe(cr, alpha * (0.10 + 0.20 * dispersion))
            cr:set_line_width(0.28)
            cr:move_to(left_x, y + 0.58)
            cr:line_to(right_x, y + 0.58)
            cr:stroke()
        end

        set_colour(cr, 0.26 + 0.36 * energy)
        cr:set_line_width(0.72)
        cr:move_to(origin_x - 1.8, y)
        cr:line_to(origin_x, y)
        cr:stroke()
    end

    local function paint_shard(cr, x, y, lit)
        local tail = 1.7 + 3.5 * lit

        set_dispersion(cr, 0.070 + 0.20 * lit)
        cr:set_line_width(1.35)
        cr:move_to(x - tail, y)
        cr:line_to(x - 0.35, y)
        cr:stroke()

        set_dispersion(cr, 0.12 + 0.24 * lit)
        cr:set_line_width(0.34)
        cr:move_to(x - tail + 0.30, y - 0.62)
        cr:line_to(x - 0.45, y - 0.62)
        cr:stroke()

        set_fringe(cr, 0.035 + 0.10 * lit)
        cr:set_line_width(0.30)
        cr:move_to(x - tail + 0.55, y + 0.62)
        cr:line_to(x - 0.45, y + 0.62)
        cr:stroke()

        set_mix(cr, 0.34, 0.22 + 0.42 * lit)
        cr:set_line_width(0.60)
        cr:move_to(x - 1.0 - 1.4 * lit, y)
        cr:line_to(x + 0.05, y)
        cr:stroke()

        set_colour(cr, 0.38 + 0.56 * lit)
        cr:move_to(x + 0.45, y)
        cr:line_to(x - 0.45, y - 0.64)
        cr:line_to(x - 0.45, y + 0.64)
        cr:close_path()
        cr:fill()
    end

    return function(cr, width, height)
        width = width or 36
        height = height or 180
        refresh_palette()

        local targets = read_targets()
        local origin_x = width - 5
        local max_length = math.max(8, origin_x - 3)
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

                paint_beam(cr, origin_x, y, length, energy)

                local shard_count = 7
                local lit_extent = energy * shard_count
                for shard = 0, shard_count - 1 do
                    local lit = clamp(lit_extent - shard, 0, 1)
                    if lit > 0.02 then
                        local x = origin_x
                            - shard * max_length / (shard_count - 1)
                        paint_shard(cr, x, y, lit)
                    end
                end
            end
        end
    end
end

return new_renderer
