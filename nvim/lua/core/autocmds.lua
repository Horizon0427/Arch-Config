local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Highlight yanked region briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Equalise splits when the terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- 2-space indent for common config/markup filetypes
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("filetype_indent"),
  pattern = { "lua", "json", "jsonc", "css", "toml", "yaml", "markdown", "html" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Close certain utility windows with just q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "man", "qf", "checkhealth", "lspinfo" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- Hide crosshair in insert mode; restore on leaving
local crosshair = augroup("crosshair")
vim.api.nvim_create_autocmd("InsertEnter", {
  group = crosshair,
  callback = function()
    vim.opt.cursorline   = false
    vim.opt.cursorcolumn = false
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group = crosshair,
  callback = function()
    vim.opt.cursorline   = true
    vim.opt.cursorcolumn = true
  end,
})

-- fcitx5: switch to ASCII whenever entering normal/command mode.
if vim.fn.executable("fcitx5-remote") == 1 then
  local function im_off()
    vim.fn.system("fcitx5-remote -c")
  end

  -- InsertLeave covers i→n; ModeChanged catches v→n and other paths
  vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = augroup("fcitx5"),
    callback = im_off,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = augroup("fcitx5"),
    -- any mode → normal (n), operator-pending (no), or select (ns)
    pattern = { "*:n", "*:no", "*:ns" },
    callback = im_off,
  })
end
