local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & indentation (default 4; overridden per filetype in autocmds)
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Wrapping
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline   = true
opt.cursorcolumn = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Files
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- Clipboard
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.mousescroll = "ver:1,hor:2"

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10

-- Diagnostics: underline + signs only, no inline virtual text
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})
