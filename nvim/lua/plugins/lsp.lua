return {
  { "williamboman/mason.nvim", cmd = "Mason", opts = {} },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "lua_ls", "taplo", "texlab" },
      automatic_installation = false,
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim", "folke/lazydev.nvim" },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
          end
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false

          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc, silent = true })
          end
          map("gd",         vim.lsp.buf.definition,     "Go to definition")
          map("gD",         vim.lsp.buf.declaration,    "Go to declaration")
          map("gr",         vim.lsp.buf.references,     "References")
          map("gi",         vim.lsp.buf.implementation, "Go to implementation")
          map("K",          vim.lsp.buf.hover,          "Hover")
          map("<C-k>",      vim.lsp.buf.signature_help, "Signature help")
          map("<leader>rn", vim.lsp.buf.rename,         "Rename")
          map("<leader>ca", vim.lsp.buf.code_action,    "Code action")
          map("<leader>e",  vim.diagnostic.open_float,  "Show diagnostics")
          map("[d",         vim.diagnostic.goto_prev,   "Prev diagnostic")
          map("]d",         vim.diagnostic.goto_next,   "Next diagnostic")
        end,
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace   = { checkThirdParty = false },
            telemetry   = { enable = false },
          },
        },
      })

      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=never",
          "--completion-style=detailed",
          "--inlay-hints=false",
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              typeCheckingMode       = "basic",
              autoSearchPaths        = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      vim.lsp.config("taplo", {})

      vim.lsp.config("texlab", {
        settings = {
          texlab = {
            build  = { onSave = false },
            chktex = { onEdit = false, onOpenAndSave = false },
          },
        },
      })


      vim.lsp.enable({ "lua_ls", "clangd", "pyright", "taplo", "texlab" })
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
}
