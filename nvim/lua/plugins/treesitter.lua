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

      -- The v1.0 (main) branch does NOT enable highlighting automatically;
      -- install() only fetches parsers. Start the treesitter highlighter on
      -- every buffer whose parser is available (pcall skips the rest, e.g.
      -- before a parser has finished installing on first launch).
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
}
