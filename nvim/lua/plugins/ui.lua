return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        terminal_colors = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        component_separators = "|",
        section_separators = "",
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  {
    "echasnovski/mini.starter",
    version = false,
    lazy = false,
    config = function()
      local starter = require("mini.starter")

      -- 增加一个 indent 变量，用空格把整个菜单块往右推，对齐标题中心
      local indent = "       " -- 这里放了7个空格，如果觉得还不够右，可以继续加空格
      local HINT_COL = 30
      local function act(icon, label, hint, action_val, sec)
        local used = vim.fn.strwidth(icon) + 2 + vim.fn.strwidth(label)
        local pad  = string.rep(" ", math.max(4, HINT_COL - used))
        return {
          section = sec or "nav",
          name    = indent .. icon .. "  " .. label .. pad .. hint,
          action  = action_val,
        }
      end

      -- 把 section 标题变为空行，让排版更透气
      local function sections_as_spacers(content)
        local out = {}
        for _, line in ipairs(content) do
          local is_sec = false
          for _, unit in ipairs(line) do
            if unit.type == "section" then is_sec = true; break end
          end
          if is_sec then
            table.insert(out, { { type = "empty", string = "" } })
          else
            table.insert(out, line)
          end
        end
        return out
      end

      -- j/k navigation: must hook AFTER MiniStarterOpened, because mini.starter
      -- re-registers all letter keys (including j/k) to add_to_query() at the
      -- end of its open() call, overwriting any FileType-based keymaps.
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniStarterOpened",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          vim.keymap.set("n", "j", "<Cmd>lua MiniStarter.update_current_item('next')<CR>",
            { buffer = buf, nowait = true, silent = true })
          vim.keymap.set("n", "k", "<Cmd>lua MiniStarter.update_current_item('prev')<CR>",
            { buffer = buf, nowait = true, silent = true })
        end,
      })

      starter.setup({
        evaluate_single = true,

        header = table.concat({
          "",
          "██╗  ██╗ ██████╗ ██████╗ ██╗███████╗ ██████╗ ███╗   ██╗",
          "██║  ██║██╔═══██╗██╔══██╗██║╚══███╔╝██╔═══██╗████╗  ██║",
          "███████║██║   ██║██████╔╝██║  ███╔╝ ██║   ██║██╔██╗ ██║",
          "██╔══██║██║   ██║██╔══██╗██║ ███╔╝  ██║   ██║██║╚██╗██║",
          "██║  ██║╚██████╔╝██║  ██║██║███████╗╚██████╔╝██║ ╚████║",
          "╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝",
          "",
          "",
        }, "\n"),

        items = {
          act("",  "Find File",    "SPC f f",  "lua require('fzf-lua').files()",     "nav"),
          act("",  "New File",     "SPC f n",  "enew",                               "nav"),
          act("󰋚",  "Recent Files", "SPC f r",  "lua require('fzf-lua').oldfiles()",  "nav"),
          act("󰍉",  "Live Grep",    "SPC f g",  "lua require('fzf-lua').live_grep()", "nav"),
          act("",  "Config",       "SPC f c",  function()
            require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
          end, "tools"),
          act("󰒲",  "Lazy",         ":Lazy  ",  "Lazy",                               "tools"),
          act("󰩈",  "Quit",         "q      ",  "qa",                                 "tools"),
        },

        content_hooks = {
          sections_as_spacers,
          starter.gen_hook.adding_bullet("  ❯ "),
          starter.gen_hook.aligning("center", "center"),
        },

        footer = function()
          local stats = require("lazy").stats()
          -- Lazy 启动极快时可能会显示 0ms，如果需要更精确可以去掉 math.floor
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          return "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms"
        end,
      })
    end,
  },
}
