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

-- Markdown: quick bold / italic helpers (localleader = "\")
--   <localleader>b  bold the word under cursor / wrap the visual selection
--   <localleader>i  italic the word under cursor / wrap the visual selection
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_emphasis"),
  pattern = "markdown",
  callback = function(ev)
    local o = { buffer = ev.buf, silent = true }
    vim.keymap.set("x", "<localleader>b", "c**<C-r>\"**<Esc>",
      vim.tbl_extend("force", o, { desc = "Bold selection" }))
    vim.keymap.set("n", "<localleader>b", "viwc**<C-r>\"**<Esc>",
      vim.tbl_extend("force", o, { desc = "Bold word" }))
    vim.keymap.set("x", "<localleader>i", "c*<C-r>\"*<Esc>",
      vim.tbl_extend("force", o, { desc = "Italic selection" }))
    vim.keymap.set("n", "<localleader>i", "viwc*<C-r>\"*<Esc>",
      vim.tbl_extend("force", o, { desc = "Italic word" }))
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

-- fcitx5: Chinese IME active only in Insert mode; state is saved/restored
-- so re-entering Insert mode resumes the same IME state as when you left.
if vim.fn.executable("fcitx5-remote") == 1 then
  local fcitx5 = augroup("fcitx5")
  -- 1 = inactive (ASCII), 2 = active (Chinese)
  local saved_im = 1

  local function im_off()
    vim.fn.system("fcitx5-remote -c")
  end

  local function im_save_and_off()
    saved_im = tonumber(vim.fn.system("fcitx5-remote")) or 1
    im_off()
  end

  local function im_restore()
    if saved_im == 2 then
      vim.fn.system("fcitx5-remote -o")
    end
  end

  -- Restore IME state on entering Insert (e.g. was Chinese before last <Esc>)
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = fcitx5,
    callback = im_restore,
  })

  -- Save state then switch to ASCII; covers i→n and command mode exit
  vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave" }, {
    group = fcitx5,
    callback = im_save_and_off,
  })

  -- Belt-and-suspenders: kill IME on any path into normal/operator/select
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = fcitx5,
    pattern = { "*:n", "*:no", "*:ns" },
    callback = im_off,
  })

  -- Override the plain jk → <Esc> keymap so it also disables Chinese IME.
  -- Pressing jk in Chinese mode switches to ASCII then exits Insert mode.
  -- (Requires the terminal to forward keystrokes through fcitx5 preedit;
  --  if fcitx5 holds `j` in preedit, use <Esc> which cancels preedit first.)
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.keymap.set("i", "jk", function()
    vim.fn.system("fcitx5-remote -c")
    vim.api.nvim_feedkeys(esc, "n", false)
  end, { silent = true, desc = "Exit insert + disable IME" })
end
