local M = {}

local uv = vim.uv or vim.loop
local cache_home = vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")
local palette_path = cache_home .. "/matugen/nvim-colors.lua"
local palette_dir = vim.fs.dirname(palette_path)
local palette_name = vim.fs.basename(palette_path)

local watcher
local debounce
local last_error

local required_colors = {
  "background",
  "surface",
  "surface_container_lowest",
  "surface_container_low",
  "surface_container",
  "surface_container_high",
  "surface_container_highest",
  "on_surface",
  "on_surface_variant",
  "outline",
  "outline_variant",
  "primary",
  "primary_container",
  "primary_fixed_dim",
  "secondary",
  "secondary_container",
  "secondary_fixed_dim",
  "tertiary",
  "tertiary_container",
  "tertiary_fixed_dim",
  "error",
  "error_container",
}

local function read_palette()
  local chunk, load_error = loadfile(palette_path)
  if not chunk then
    return nil, load_error
  end

  local ok, palette = pcall(chunk)
  if not ok then
    return nil, palette
  end
  if type(palette) ~= "table" then
    return nil, "palette did not return a table"
  end

  for _, name in ipairs(required_colors) do
    local value = palette[name]
    if type(value) ~= "string" or not value:match("^#%x%x%x%x%x%x$") then
      return nil, ("invalid or missing colour %q"):format(name)
    end
  end
  return palette
end

local function theme_options()
  return {
    style = "matugen",
    transparent = true,
    terminal_colors = true,
    cache = false,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  }
end

local function install_palette(p)
  require("tokyonight.colors").styles.matugen = function()
    local base = vim.deepcopy(require("tokyonight.colors.night"))
    return vim.tbl_deep_extend("force", base, {
      bg = p.background,
      bg_dark = p.surface_container_low,
      bg_dark1 = p.surface_container_lowest,
      bg_highlight = p.surface_container_high,

      fg = p.on_surface,
      fg_dark = p.on_surface_variant,
      fg_gutter = p.outline_variant,
      comment = p.outline,
      dark3 = p.outline_variant,
      dark5 = p.outline,
      terminal_black = p.surface_container_highest,

      blue = p.primary,
      blue0 = p.primary_container,
      blue1 = p.secondary,
      blue2 = p.primary,
      blue5 = p.secondary,
      blue6 = p.secondary_fixed_dim,
      blue7 = p.surface_container_highest,
      cyan = p.secondary,
      green = p.tertiary,
      green1 = p.tertiary_fixed_dim,
      green2 = p.tertiary,
      magenta = p.primary_fixed_dim,
      magenta2 = p.error,
      orange = p.primary,
      purple = p.secondary,
      red = p.error,
      red1 = p.error,
      teal = p.tertiary,
      yellow = p.secondary_fixed_dim,

      git = {
        add = p.tertiary,
        change = p.primary,
        delete = p.error,
      },
    })
  end
end

function M.apply(opts)
  opts = opts or {}
  local palette, palette_error = read_palette()
  if not palette then
    if opts.notify and palette_error ~= last_error then
      vim.notify("Matugen theme: " .. tostring(palette_error), vim.log.levels.WARN)
    end
    last_error = palette_error
    return false
  end

  last_error = nil
  install_palette(palette)
  require("tokyonight").setup(theme_options())
  vim.cmd.colorscheme("tokyonight")

  if opts.notify then
    vim.notify("Matugen theme reloaded")
  end
  return true
end

local function stop_watcher()
  if debounce then
    debounce:stop()
    debounce:close()
    debounce = nil
  end
  if watcher then
    watcher:stop()
    watcher:close()
    watcher = nil
  end
end

local function start_watcher()
  stop_watcher()
  vim.fn.mkdir(palette_dir, "p")

  debounce = uv.new_timer()
  watcher = uv.new_fs_event()
  local ok, watch_error = watcher:start(palette_dir, {}, function(error, filename)
    if error or (filename and filename ~= palette_name) then
      return
    end
    debounce:stop()
    debounce:start(80, 0, vim.schedule_wrap(function()
      if not vim.v.exiting or vim.v.exiting == vim.NIL then
        M.apply({ notify = false })
      end
    end))
  end)

  if not ok then
    stop_watcher()
    vim.notify_once("Matugen theme watcher failed: " .. tostring(watch_error), vim.log.levels.WARN)
  end
end

function M.setup()
  if not M.apply({ notify = false }) then
    -- First boot before Matugen has rendered the template: retain the previous
    -- transparent TokyoNight Night theme until the palette file appears.
    require("tokyonight").setup(vim.tbl_deep_extend("force", theme_options(), {
      style = "night",
    }))
    vim.cmd.colorscheme("tokyonight")
  end

  start_watcher()

  local group = vim.api.nvim_create_augroup("matugen_theme", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = stop_watcher,
  })

  vim.api.nvim_create_user_command("MatugenReload", function()
    M.apply({ notify = true })
  end, { desc = "Reload the Matugen-generated colour palette", force = true })
end

return M
