-- Short display name of the active Python venv, for the statusline
-- (lua/plugins/ui.lua, lualine_x). Queries venv-selector.nvim (lua/plugins/
-- venv.lua) directly instead of going through state.register, since lualine
-- already re-evaluates its components on every redraw -- no event wiring
-- needed. Guarded via package.loaded because venv-selector only lazy-loads
-- on ft=python (see venv.lua) and simply isn't loaded yet in other buffers.

local M = {}

--- Current venv as a short display name, or "" if none active/detected.
--- Meant to be used as a lualine custom component function (component = "").
---@return string
function M.status()
  if not package.loaded["venv-selector"] then
    return ""
  end
  local ok, path = pcall(function() return require("venv-selector").venv() end)
  if not ok or not path or path == "" then
    return ""
  end
  local icon = require("nvim-web-devicons").get_icon_by_filetype("python", { default = true })
  return (icon or "") .. " " .. vim.fn.fnamemodify(path, ":t")
end

return M
