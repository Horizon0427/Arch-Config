-- Disable netrw so nvim-tree handles directory opens
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>E", "<cmd>NvimTreeToggle<CR>",   desc = "Toggle file tree" },
      { "<leader>o", "<cmd>NvimTreeFocus<CR>",    desc = "Focus file tree" },
    },
    opts = {
      view = {
        width = 30,
        side  = "left",
      },
      renderer = {
        group_empty        = true,
        highlight_git      = true,
        indent_markers     = { enable = true },
      },
      git = {
        enable = true,
        ignore = false,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          window_picker = { enable = true },
        },
      },
      filters = {
        dotfiles = false,
      },
      -- Auto-close when nvim-tree is the only remaining window
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        -- close tree when it's the last window
        vim.api.nvim_create_autocmd("WinClosed", {
          buffer = bufnr,
          callback = function()
            vim.schedule(function()
              if #vim.api.nvim_list_wins() == 1 then
                local last = vim.api.nvim_list_wins()[1]
                local buf  = vim.api.nvim_win_get_buf(last)
                if vim.bo[buf].filetype == "NvimTree" then
                  vim.cmd("quit")
                end
              end
            end)
          end,
        })
      end,
    },
  },
}
