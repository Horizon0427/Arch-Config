return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,   -- v1.0+ does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- New v1.0 API: no configs module, no setup() for basic use.
      -- Highlight and indent are provided by Neovim's built-in treesitter.
      -- Install parsers asynchronously on first launch.
      require("nvim-treesitter").install({
        "bash", "c", "lua", "vim", "vimdoc",
        "python", "markdown", "markdown_inline",
        "json", "toml", "yaml", "css", "latex",
      })
    end,
  },
}
