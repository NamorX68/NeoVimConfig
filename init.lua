-- Entry point for the Neovim configuration.
--
-- Load order matters here:
--   1. Leader keys must be set before lazy.nvim loads any plugin that reads
--      them during its own setup().
--   2. `settings` (lua/settings/init.lua) is a pure-data module with zero
--      plugin dependencies, so it can be required before lazy.nvim runs --
--      this lets plugins like the colorscheme read the persisted user
--      choice on the very first frame, with no flash of the wrong theme.
--   3. Core editor options/keymaps/autocmds have no plugin dependencies
--      either and are applied next.
--   4. lua/config/lazy.lua bootstraps lazy.nvim and imports every spec
--      under lua/plugins/*.lua last.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable built-in plugins we replace with dedicated ones (netrw is
-- replaced by neo-tree.nvim, see lua/plugins/neotree.lua).
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("settings")
require("config.options")
require("config.keymaps").apply()
require("config.autocmds")
require("config.lazy")
