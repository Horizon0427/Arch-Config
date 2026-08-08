return {
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
        preset   = "default",
        ["<C-Space>"] = { "show", "fallback" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<Tab>"]     = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
        ["<C-n>"]     = { "select_next", "fallback" },
        ["<C-p>"]     = { "select_prev", "fallback" },
        ["<C-e>"]     = { "cancel", "fallback" },
      },

      completion = {
        trigger = {
          show_on_keyword                    = false,
          show_on_trigger_character          = true,
          show_on_insert_on_trigger_character = true,
        },
        documentation = {
          auto_show       = false,
          auto_show_delay_ms = 500,
          window = { border = "rounded" },
        },
        list = { max_items = 12 },
        menu = { border = "rounded" },
      },

      signature = { enabled = false },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },
}
