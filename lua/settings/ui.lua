-- The "Konfigurationsmaske" -- a floating settings window built on
-- nui.nvim (already a dependency of noice.nvim/neo-tree, see
-- lua/plugins/ui.lua and lua/plugins/neotree.lua), covering every toggle
-- listed in lua/settings/state.lua's schema. Opened via <leader>cs,
-- `:Settings`, the command palette, or the dashboard.
--
-- Every change goes through settings.state.set(), which persists it AND
-- runs whatever applier the owning plugin module registered (colorscheme
-- switching in lua/util/theme.lua, LSP enable/disable in
-- lua/plugins/lsp.lua, bufferline visibility in lua/plugins/ui.lua, ...) --
-- this module only builds/renders the rows and dispatches toggles, it
-- never applies a setting's side effect itself.
--
-- Layout: a top tab bar (one tab per section) plus only the active tab's
-- rows below it, rather than one long flat scrolling list. Colors come from
-- lua/settings/highlights.lua, which links to the active colorscheme.

local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local highlights = require("settings.highlights")

local M = {}

local NS = vim.api.nvim_create_namespace("nvim_settings_ui")

local LANGUAGE_LABELS = {
  python = "Python",
  rust = "Rust",
  css = "CSS",
  html = "HTML",
  javascript = "JavaScript / TypeScript",
  cpp = "C / C++",
  docker = "Docker",
}

local LANGUAGE_ORDER = { "python", "rust", "css", "html", "javascript", "cpp", "docker" }

--- One entry per tab. `rows(state)` is rebuilt on every render so options
--- that depend on other settings (the colorscheme variant list depends on
--- which colorscheme is selected) stay correct after a toggle.
local SECTIONS = {
  {
    title = "Appearance",
    rows = function(state)
      local s = state.get()
      local theme_entry = require("util.theme").THEMES[s.colorscheme]
      return {
        { kind = "select", key = "colorscheme", label = "Colorscheme",
          options = { "catppuccin", "tokyonight", "gruvbox", "kanagawa", "github", "cyberdream" } },
        { kind = "select", key = "colorscheme_variant", label = "Variant", options = theme_entry.variants },
        { kind = "toggle", key = "background_transparency", label = "Transparent background" },
      }
    end,
  },
  {
    title = "Diagnostics / Editor",
    rows = function()
      return {
        { kind = "select", key = "diagnostics_style", label = "Diagnostics style",
          options = { "virtual_text", "current_line", "virtual_lines", "inline" } },
        { kind = "toggle", key = "inlay_hints", label = "Inlay hints" },
        { kind = "toggle", key = "indent_guides", label = "Indent guides" },
        { kind = "toggle", key = "relativenumber", label = "Relative line numbers" },
      }
    end,
  },
  {
    title = "Formatting",
    rows = function()
      local rows = {
        { kind = "toggle", key = "format_on_save", label = "Format on save (global)" },
      }
      for _, filetype in ipairs({ "python", "rust", "css", "html", "javascript", "typescript", "c", "cpp" }) do
        table.insert(rows, { kind = "format_ft", filetype = filetype, label = "." .. filetype .. " override" })
      end
      return rows
    end,
  },
  {
    title = "Languages",
    rows = function()
      local rows = {}
      for _, lang in ipairs(LANGUAGE_ORDER) do
        table.insert(rows, { kind = "language", lang = lang, label = LANGUAGE_LABELS[lang] })
      end
      return rows
    end,
  },
  {
    title = "UI layout",
    rows = function()
      return {
        { kind = "toggle", key = "bufferline_visible", label = "Show bufferline" },
        { kind = "select", key = "statusline_style", label = "Statusline style", options = { "default", "minimal" } },
      }
    end,
  },
  {
    title = "Reference",
    rows = function()
      return {
        { kind = "action", label = "Keymap reference (opens command palette)" },
      }
    end,
  },
}

--- Symbol + highlight group shown for `row`'s current value.
---@param row table
---@param state table
---@return string symbol, string hl_group
local function value_display(row, state)
  local s = state.get()
  if row.kind == "toggle" then
    return (s[row.key] and "✓" or "✗"), (s[row.key] and "NvimSettingsOk" or "NvimSettingsErr")
  elseif row.kind == "select" then
    return "‹ " .. tostring(s[row.key]) .. " ›", "NvimSettingsAccent"
  elseif row.kind == "language" then
    local on = s.languages[row.lang] ~= false
    return (on and "✓" or "✗"), (on and "NvimSettingsOk" or "NvimSettingsErr")
  elseif row.kind == "format_ft" then
    -- Tri-state: nil = inherit the global format_on_save value, true/false
    -- pins this filetype regardless of the global toggle (see the
    -- format-on-save autocmd in lua/config/autocmds.lua).
    local override = s.format_on_save_filetype[row.filetype]
    if override == nil then
      return "inherit", "NvimSettingsMuted"
    end
    return (override and "on" or "off"), (override and "NvimSettingsOk" or "NvimSettingsErr")
  end
  return "→", "NvimSettingsAccent"
end

--- One-line contextual help for the row under the cursor, shown in the
--- footer. Derived from the row instead of authored per-row, so adding a
--- new row never risks a missing/stale hint.
---@param row table?
---@return string
local function hint_for(row)
  if not row then
    return "j/k move   Tab/S-Tab switch tab   q/Esc close"
  elseif row.kind == "toggle" or row.kind == "language" then
    return string.format('<CR>/<Space> toggle "%s"', row.label)
  elseif row.kind == "select" then
    return string.format('<CR>/<Space> cycle "%s" (%s)', row.label, table.concat(row.options, ", "))
  elseif row.kind == "format_ft" then
    return string.format("<CR>/<Space> cycle %s: inherit → on → off", row.label)
  elseif row.kind == "action" then
    return "<CR>/<Space> open the keymap reference"
  end
  return ""
end

--- Render the tab bar + the active tab's rows into buffer lines, plus a
--- line-number -> row lookup (non-selectable lines map to nil) and a list of
--- (line, col_start, col_end, hl_group) highlight requests.
---@param state table
---@param tab_index integer
---@return string[] lines, table<integer, table> line_to_row, table[] highlights
local function render(state, tab_index)
  local lines = {}
  local line_to_row = {}
  local hl = {}

  -- Tab bar (line 1, 0-indexed line 0). Columns are BYTE offsets (what
  -- nvim_buf_add_highlight expects), so the separator's byte length is used
  -- rather than assuming 1 -- "│" is a 3-byte UTF-8 sequence, not 1 byte.
  local SEP = "│"
  local tab_parts = {}
  local col = 1
  for i, section in ipairs(SECTIONS) do
    local text = " " .. section.title .. " "
    table.insert(tab_parts, text)
    local group = (i == tab_index) and "NvimSettingsTabActive" or "NvimSettingsTabInactive"
    table.insert(hl, { line = 0, col_start = col, col_end = col + #text, group = group })
    col = col + #text + #SEP
  end
  table.insert(lines, " " .. table.concat(tab_parts, SEP))
  table.insert(lines, "")

  for _, row in ipairs(SECTIONS[tab_index].rows(state)) do
    local symbol, group = value_display(row, state)
    local prefix = "    "
    local text = prefix .. symbol .. "  " .. row.label
    table.insert(lines, text)
    table.insert(hl, { line = #lines - 1, col_start = #prefix, col_end = #prefix + #symbol, group = group })
    line_to_row[#lines] = row
  end

  table.insert(lines, "")
  table.insert(lines, "") -- footer line, filled in by the caller (needs cursor position)

  return lines, line_to_row, hl
end

--- Apply the effect of activating `row` (toggle a boolean, cycle a select,
--- flip one language, or run an action), then persist via state.set().
---@param row table
---@param state table
local function activate_row(row, state)
  local s = state.get()
  if row.kind == "toggle" then
    state.set(row.key, not s[row.key])
  elseif row.kind == "select" then
    local current_index = 1
    for i, option in ipairs(row.options) do
      if option == s[row.key] then
        current_index = i
        break
      end
    end
    local next_option = row.options[(current_index % #row.options) + 1]
    state.set(row.key, next_option)
  elseif row.kind == "language" then
    local languages = vim.deepcopy(s.languages)
    languages[row.lang] = not (languages[row.lang] ~= false)
    state.set("languages", languages)
  elseif row.kind == "format_ft" then
    -- Cycle nil -> true -> false -> nil.
    local overrides = vim.deepcopy(s.format_on_save_filetype)
    local current = overrides[row.filetype]
    if current == nil then
      overrides[row.filetype] = true
    elseif current == true then
      overrides[row.filetype] = false
    else
      overrides[row.filetype] = nil
    end
    state.set("format_on_save_filetype", overrides)
  elseif row.kind == "action" then
    require("legendary").find({ filters = { require("legendary.filters").keymaps() } })
  end
end

--- Open the settings window. Safe to call repeatedly; reuses nothing --
--- each call mounts a fresh popup and tears it down on close.
function M.open()
  highlights.apply() -- defensive: groups must exist even if util.theme hasn't run yet
  local state = require("settings").state
  local tab_index = 1

  -- Size the window for the tab with the most rows, so it doesn't visibly
  -- resize when switching tabs.
  local max_rows = 0
  for _, section in ipairs(SECTIONS) do
    max_rows = math.max(max_rows, #section.rows(state))
  end

  local popup = Popup({
    position = "50%",
    size = { width = 70, height = math.min(max_rows + 6, 30) },
    enter = true,
    focusable = true,
    zindex = 50,
    border = {
      style = "rounded",
      text = { top = " Settings (Konfigurationsmaske) ", top_align = "center" },
    },
    buf_options = { modifiable = false, readonly = false, filetype = "nvim-settings" },
    win_options = { cursorline = true, winblend = 0 },
  })

  popup:mount()

  local line_to_row

  local function current_row()
    local cursor_line = vim.api.nvim_win_get_cursor(popup.winid)[1]
    return line_to_row[cursor_line]
  end

  local function redraw()
    local lines, hl
    lines, line_to_row, hl = render(state, tab_index)
    lines[#lines] = "  " .. hint_for(current_row())

    vim.bo[popup.bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
    vim.bo[popup.bufnr].modifiable = false

    vim.api.nvim_buf_clear_namespace(popup.bufnr, NS, 0, -1)
    for _, h in ipairs(hl) do
      vim.api.nvim_buf_add_highlight(popup.bufnr, NS, h.group, h.line, h.col_start, h.col_end)
    end
  end

  --- Redraw just the footer line without touching the tab bar/rows/cursor --
  --- used on plain cursor movement, where nothing else changed.
  local function redraw_footer()
    local last_line = vim.api.nvim_buf_line_count(popup.bufnr)
    vim.bo[popup.bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(popup.bufnr, last_line - 1, last_line, false, { "  " .. hint_for(current_row()) })
    vim.bo[popup.bufnr].modifiable = false
  end

  redraw()

  local function on_activate()
    local row = current_row()
    if row then
      activate_row(row, state)
      redraw()
    end
  end

  local function switch_tab(new_index)
    tab_index = ((new_index - 1) % #SECTIONS) + 1
    redraw()
    -- Land on the first selectable row of the new tab (line 3: tab bar,
    -- blank, first row) rather than keeping a cursor position that may not
    -- exist in the new tab's (shorter) row list.
    vim.api.nvim_win_set_cursor(popup.winid, { 3, 0 })
  end

  local map_opts = { noremap = true, nowait = true }
  popup:map("n", "<CR>", on_activate, map_opts)
  popup:map("n", "<Space>", on_activate, map_opts)
  popup:map("n", "<Tab>", function() switch_tab(tab_index + 1) end, map_opts)
  popup:map("n", "<S-Tab>", function() switch_tab(tab_index - 1) end, map_opts)
  for i = 1, #SECTIONS do
    popup:map("n", tostring(i), function() switch_tab(i) end, map_opts)
  end
  popup:map("n", "q", function() popup:unmount() end, map_opts)
  popup:map("n", "<Esc>", function() popup:unmount() end, map_opts)

  popup:on(event.CursorMoved, redraw_footer)
  popup:on(event.BufLeave, function()
    popup:unmount()
  end)
end

return M
