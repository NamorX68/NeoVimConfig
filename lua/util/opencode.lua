-- Opencode AI CLI terminal helper, shared between two call sites that must
-- target the exact same terminal instance:
--   1. vim.g.opencode_opts.server.start (lua/plugins/opencode.lua) --
--      opencode.nvim calls this itself the first time ask()/select() needs
--      a live server connection.
--   2. <leader>ot (lua/config/keymaps.lua) -- manual show/hide.
-- Both going through this one function with identical snacks.terminal args
-- means opencode.nvim auto-spawning the server and toggling it by hand
-- always act on one shared terminal, never two competing ones. Lives
-- outside lua/plugins/ for the same reason as lua/util/terminal.lua.

local M = {}

--- Toggle the opencode server terminal, right-side split like Claude Code's
--- panel (lua/plugins/claude.lua) -- one consistent position for both AI
--- tool panels instead of opencode.nvim's own default (a left vsplit).
function M.toggle()
  require("snacks.terminal").toggle("opencode --port", {
    win = { position = "right", width = 0.30 },
  })
end

return M
