return {
  {
    "lervag/vimtex",
    lazy = false,
    ft = { "tex", "latex", "bib" },
    init = function()
      vim.g.vimtex_view_method = "zathura"

      vim.g.vimtex_compiler_latexmk_engines = {
        _ = "-xelatex",
      }

      vim.g.vimtex_compiler_latexmk = {
        build_dir  = "",
        continuous = 1,
        executable = "latexmk",
        options    = {
          "-verbose",
          "-file-line-error",
          "-synctex=1",
          "-interaction=nonstopmode",
        },
      }

      vim.g.vimtex_view_forward_search_on_start = false
      -- Suppress most quickfix noise; only open on error
      vim.g.vimtex_quickfix_open_on_warning = 0
    end,
  },
}
