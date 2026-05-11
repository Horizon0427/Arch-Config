return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,            desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,      desc = "Flash treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,           desc = "Flash remote" },
      { "R", mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Flash treesitter search" },
    },
  },
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = {},
  },
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(l, r, desc)
          vim.keymap.set("n", l, r, { buffer = bufnr, desc = desc, silent = true })
        end
        map("]h", gs.next_hunk,                                  "Next hunk")
        map("[h", gs.prev_hunk,                                  "Prev hunk")
        map("<leader>hs", gs.stage_hunk,                         "Stage hunk")
        map("<leader>hr", gs.reset_hunk,                         "Reset hunk")
        map("<leader>hp", gs.preview_hunk,                       "Preview hunk")
        map("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("<leader>hd", gs.diffthis,                           "Diff this")
      end,
    },
  },
}
