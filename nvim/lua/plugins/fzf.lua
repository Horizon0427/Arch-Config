return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ff", function() require("fzf-lua").files() end,                    desc = "Find files" },
      { "<leader>fg", function() require("fzf-lua").live_grep() end,                desc = "Live grep" },
      { "<leader>fb", function() require("fzf-lua").buffers() end,                  desc = "Buffers" },
      { "<leader>fr", function() require("fzf-lua").oldfiles() end,                 desc = "Recent files" },
      { "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end,     desc = "Document symbols" },
      { "<leader>fS", function() require("fzf-lua").lsp_workspace_symbols() end,    desc = "Workspace symbols" },
      { "<leader>fd", function() require("fzf-lua").diagnostics_document() end,     desc = "Document diagnostics" },
      { "<leader>/",  function() require("fzf-lua").grep_curbuf() end,              desc = "Search in buffer" },
    },
    opts = {
      winopts = {
        border  = "rounded",
        preview = { border = "border" },
      },
      -- Trade-off: j/k can no longer be typed in the query box;
      keymap = {
        fzf = {
          ["j"]       = "down",
          ["k"]       = "up",
          ["ctrl-j"]  = "down",
          ["ctrl-k"]  = "up",
          ["ctrl-d"]  = "preview-page-down",
          ["ctrl-u"]  = "preview-page-up",
        },
      },
    },
  },
}
