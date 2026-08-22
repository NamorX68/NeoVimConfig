-- Core editor options. No plugin dependencies -- safe to load before
-- lazy.nvim. Plugin-specific options live next to their plugin's spec
-- instead (e.g. completeopt tweaks that only matter for blink.cmp stay
-- here since they are genuinely global, not plugin-owned).

local opt = vim.opt
local state = require("settings").state

-- UI
opt.number = true
opt.relativenumber = state.get().relativenumber
state.register("relativenumber", function(enabled)
  vim.opt.relativenumber = enabled
end)
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.laststatus = 3 -- one global statusline (lualine) instead of per-window
opt.cmdheight = 1 -- noice.nvim overrides the visual presentation, not this
opt.pumheight = 12
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "-", foldclose = "+" }
opt.splitright = true
opt.splitbelow = true

-- Editing
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.completeopt = { "menu", "menuone", "noselect" }

-- Files / undo
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.updatetime = 200
opt.timeoutlen = 400
opt.autoread = true

-- Clipboard / mouse
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- Static diagnostic cosmetics that don't depend on the persisted display
-- style (virtual_text vs. virtual_lines vs. tiny-inline-diagnostic.nvim --
-- see lua/plugins/diagnostics.lua, which owns virtual_text/virtual_lines and
-- applies the "diagnostics_style" setting once that plugin loads).
vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})
