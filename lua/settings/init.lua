-- Glue module for the "Konfigurationsmaske" settings subsystem.
--
-- `settings.state` has zero plugin dependencies and is required eagerly
-- from init.lua, before lazy.nvim runs. `settings.ui` depends on nui.nvim
-- and is only required lazily, the first time the settings window is
-- actually opened -- requiring THIS module never pulls nui.nvim in.

local M = {}

M.state = require("settings.state")

--- Open the settings floating window (lazy-requires the nui.nvim UI).
function M.open()
  require("settings.ui").open()
end

vim.api.nvim_create_user_command("Settings", M.open, {
  desc = "Open the Neovim settings UI (Konfigurationsmaske)",
})

return M
