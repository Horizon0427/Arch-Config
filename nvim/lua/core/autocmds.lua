local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("filetype_indent"),
  pattern = { "lua", "json", "jsonc", "css", "toml", "yaml", "markdown", "html" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

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

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "man", "qf", "checkhealth", "lspinfo" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

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

if vim.fn.executable("fcitx5-remote") == 1 then
  local fcitx5 = augroup("fcitx5")

  local INACTIVE, ACTIVE = 1, 2 -- fcitx5-remote 的状态码：1=英文/未激活 2=中文
  local FLAG = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/nvim-jk-escape"
  local saved_insert = INACTIVE
  local saved_cmdline = {} -- 按命令行类型（: / ? 等）分别记忆

  local function im_state()
    local ok, res = pcall(function()
      return vim.system({ "fcitx5-remote" }, { text = true }):wait(300)
    end)
    if not ok then
      return INACTIVE
    end
    return tonumber(((res.stdout or ""):match("%d+"))) or INACTIVE
  end

  local function im_set(state)
    pcall(vim.system, { "fcitx5-remote", state == ACTIVE and "-o" or "-c" })
  end

  local function mark_insert(on)
    if on then
      local f = io.open(FLAG, "w")
      if f then
        f:write(tostring(vim.fn.getpid()))
        f:close()
      end
    else
      os.remove(FLAG)
    end
  end

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = fcitx5,
    callback = function()
      mark_insert(true)
      if saved_insert == ACTIVE then
        im_set(ACTIVE)
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = fcitx5,
    callback = function()
      mark_insert(false)
      saved_insert = im_state()
      if saved_insert == ACTIVE then
        im_set(INACTIVE)
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineEnter", {
    group = fcitx5,
    callback = function(ev)
      if saved_cmdline[ev.file] == ACTIVE then
        im_set(ACTIVE)
      end
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = fcitx5,
    callback = function(ev)
      saved_cmdline[ev.file] = im_state()
      if saved_cmdline[ev.file] == ACTIVE then
        im_set(INACTIVE)
      end
    end,
  })

  vim.api.nvim_create_autocmd("FocusLost", {
    group = fcitx5,
    callback = function()
      mark_insert(false)
    end,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = fcitx5,
    callback = function()
      if vim.fn.mode():sub(1, 1) == "i" then
        mark_insert(true)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = fcitx5,
    callback = function()
      mark_insert(false)
      im_set(INACTIVE)
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = fcitx5,
    callback = function()
      mark_insert(false)
      pcall(function()
        vim.system({ "fcitx5-remote", "-c" }):wait(300)
      end)
    end,
  })
end
