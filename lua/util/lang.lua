-- Maps Neovim filetypes to the language keys used in settings.state's
-- `languages` table (see lua/settings/state.lua) and to the LSP server
-- names lua/plugins/lsp.lua registers for each. Shared by lsp.lua
-- (enable/disable LSP clients), lua/config/autocmds.lua (format-on-save
-- gate) and lua/plugins/linting.lua (lint gate) so this mapping only lives
-- in one place.
--
-- Lives outside lua/plugins/ for the same reason as lua/util/theme.lua:
-- lazy.nvim's `{ import = "plugins" }` treats every file directly under
-- lua/plugins/ as a plugin-spec module.

local M = {}

M.FILETYPE_TO_LANGUAGE = {
  python = "python",
  rust = "rust",
  css = "css",
  scss = "css",
  html = "html",
  javascript = "javascript",
  javascriptreact = "javascript",
  typescript = "javascript",
  typescriptreact = "javascript",
  c = "cpp",
  cpp = "cpp",
  dockerfile = "docker",
}

-- rust is intentionally mapped to an empty server list: rustaceanvim owns
-- its own client lifecycle by filetype and is not toggled via vim.lsp.enable.
M.LANGUAGE_TO_LSP_SERVERS = {
  python = { "basedpyright", "ruff" },
  rust = {},
  css = { "cssls" },
  html = { "html" },
  javascript = { "ts_ls", "eslint" },
  cpp = { "clangd" },
  docker = { "dockerls", "docker_compose_language_service" },
}

--- Whether the language backing `filetype` is currently enabled in settings.
--- Filetypes with no language mapping (lua, markdown, json, ...) are always
--- treated as enabled -- the per-language toggles only cover the 6
--- explicitly in-scope languages plus Docker.
---@param filetype string
---@return boolean
function M.is_enabled(filetype)
  local language = M.FILETYPE_TO_LANGUAGE[filetype]
  if not language then
    return true
  end
  local languages = require("settings").state.get().languages
  return languages[language] ~= false
end

return M
