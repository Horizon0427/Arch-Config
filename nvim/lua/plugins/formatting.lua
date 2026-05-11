return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd   = { "ConformInfo" },
    keys  = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        c      = { "clang_format" },
        cpp    = { "clang_format" },
        python = { "ruff_format" },
        lua    = { "stylua" },
        toml   = { "taplo" },
      },
      -- Format on save intentionally disabled; use <leader>cf
      format_on_save = nil,
    },
  },
}
