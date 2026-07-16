-- Bold styling for selected syntax elements.
-- Re-applied on every ColorScheme event so it survives theme switches/reloads.

-- Treesitter capture groups rendered bold in code. Edit to taste.
--   @type.builtin     int, char, float, double, bool, void, ...
--   @keyword.modifier const, static, extern, volatile, inline, ...
--   @keyword.type     struct, enum, union, class, typedef, ...
local code_bold = {
  "@type.builtin",
  "@keyword.modifier",
  "@keyword.type",
}

-- Markup groups rendered bold (e.g. **strong** in Markdown).
local markup_bold = {
  "@markup.strong",
}

-- Add the bold attribute to a highlight group while keeping its colours.
-- Resolves links (link = false) so we freeze the effective colour, then
-- merely flip `bold`; this is re-run per ColorScheme so colours stay correct.
local function add_bold(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok then return end
  hl = hl or {}
  hl.bold = true
  hl.default = nil
  vim.api.nvim_set_hl(0, group, hl)
end

local function apply()
  for _, g in ipairs(code_bold) do add_bold(g) end
  for _, g in ipairs(markup_bold) do add_bold(g) end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("bold_syntax", { clear = true }),
  callback = apply,
})

-- Apply once now in case a colorscheme is already active.
apply()
