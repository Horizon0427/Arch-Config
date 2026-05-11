local map = function(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Better escape
map("i", "jk", "<Esc>")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Save / Quit
map("n", "<leader>w", "<cmd>w<CR>",  { desc = "Save" })
map("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all" })
map("n", "<leader>q", "<cmd>q<CR>",  { desc = "Quit" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Window resize
map("n", "<C-Up>",    "<cmd>resize +2<CR>")
map("n", "<C-Down>",  "<cmd>resize -2<CR>")
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>")

-- Buffer navigation
map("n", "<S-l>",      "<cmd>bnext<CR>",    { desc = "Next buffer" })
map("n", "<S-h>",      "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>",  { desc = "Delete buffer" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<CR>==")
map("n", "<A-k>", "<cmd>m .-2<CR>==")
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Keep indent selection
map("v", "<", "<gv")
map("v", ">", ">gv")

-- New split
map("n", "<leader>|", "<cmd>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>-", "<cmd>split<CR>",  { desc = "Horizontal split" })
