-- Persisted user settings backing the custom "Konfigurationsmaske" (settings
-- UI, see lua/settings/ui.lua). Pure data module: NO plugin dependencies, so
-- it is safe to require before lazy.nvim has loaded anything -- this lets
-- e.g. the saved colorscheme apply on the very first frame.
--
-- Usage:
--   local state = require("settings.state")
--   state.get().format_on_save        -- read
--   state.set("format_on_save", false) -- write + persist + run applier
--   state.register("format_on_save", function(v) ... end) -- side effect

local M = {}

local settings_path = vim.fn.stdpath("data") .. "/nvim_settings.json"

local defaults = {
  colorscheme = "catppuccin",
  colorscheme_variant = "mocha", -- catppuccin flavor; ignored by themes without variants
  background_transparency = false,
  format_on_save = true,
  format_on_save_filetype = {}, -- per-filetype override, e.g. { python = false }
  -- "virtual_text" | "current_line" | "virtual_lines" | "inline" -- see
  -- lua/plugins/diagnostics.lua for what each renders.
  diagnostics_style = "virtual_text",
  inlay_hints = true,
  indent_guides = true,
  relativenumber = true,
  bufferline_visible = true,
  statusline_style = "default", -- "default" | "minimal"
  languages = {
    python = true,
    rust = true,
    css = true,
    html = true,
    javascript = true,
    cpp = true,
    docker = true,
  },
}

-- Side-effect callbacks registered by plugin modules once THEY are loaded,
-- e.g. `appliers.colorscheme = function(v) vim.cmd.colorscheme(v) end`.
-- Kept separate from `defaults`/`current` precisely so this module never
-- needs to `require` a plugin itself.
M.appliers = {}

local current = nil

local function read_file()
  local f = io.open(settings_path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return nil
  end
  return decoded
end

local function write_file(data)
  local f = io.open(settings_path, "w")
  if not f then
    vim.notify("settings.state: could not write " .. settings_path, vim.log.levels.WARN)
    return
  end
  f:write(vim.json.encode(data))
  f:close()
end

-- Recursively fill missing keys in `tbl` from `defaults_tbl`, so the schema
-- can grow across config versions without discarding an existing file.
local function merge_defaults(tbl, defaults_tbl)
  for key, value in pairs(defaults_tbl) do
    if tbl[key] == nil then
      tbl[key] = value
    elseif type(value) == "table" and type(tbl[key]) == "table" then
      merge_defaults(tbl[key], value)
    end
  end
  return tbl
end

--- Load persisted settings from disk, falling back to defaults on first run
--- or a corrupt file. Idempotent; cheap to call repeatedly.
---@return table
function M.load()
  if current then
    return current
  end
  local loaded = read_file()
  current = merge_defaults(loaded or {}, defaults)
  return current
end

--- Get the full settings table (loads from disk on first call).
---@return table
function M.get()
  return M.load()
end

--- Persist the current in-memory settings table to disk.
function M.save()
  if current then
    write_file(current)
  end
end

--- Set a top-level setting, run its registered applier (if any), then persist.
---@param key string
---@param value any
function M.set(key, value)
  local settings = M.load()
  settings[key] = value
  local applier = M.appliers[key]
  if applier then
    local ok, err = pcall(applier, value)
    if not ok then
      vim.notify(string.format("settings.state: applier for %q failed: %s", key, err), vim.log.levels.ERROR)
    end
  end
  M.save()
end

--- Register a side-effecting function to run whenever `key` changes via
--- M.set(). Called by plugin modules from their own config() function.
---@param key string
---@param fn fun(value: any)
function M.register(key, fn)
  M.appliers[key] = fn
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  desc = "Persist settings as a safety net on exit",
  callback = M.save,
})

return M
