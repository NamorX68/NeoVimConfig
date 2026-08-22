-- Theme-aware highlight groups for the settings UI ("Konfigurationsmaske").
--
-- Deliberately lives under lua/settings/ (not lua/util/) since it is only
-- ever consumed by lua/settings/ui.lua. Every group LINKS to a highlight the
-- active colorscheme already defines, so the settings window always matches
-- the current theme without this module hardcoding a single color.
--
-- settings.state only keeps ONE registered applier per key (see
-- settings/state.lua's M.appliers), and lua/util/theme.lua already owns the
-- "colorscheme" / "colorscheme_variant" / "background_transparency" keys --
-- so this module does not call state.register() itself. Instead,
-- lua/util/theme.lua calls M.apply() directly at the end of its own
-- M.apply(), right after activating the new colorscheme. lua/settings/ui.lua
-- also calls it defensively before opening, so the groups exist even if
-- util.theme hasn't run yet for some reason.

local M = {}

-- Link target -> our name. Picked from groups every one of the 5 selectable
-- colorschemes defines, so no theme leaves one of these unlinked.
local GROUPS = {
  NvimSettingsTabActive = "TabLineSel",
  NvimSettingsTabInactive = "TabLine",
  NvimSettingsAccent = "Title",
  NvimSettingsOk = "DiagnosticOk",
  NvimSettingsErr = "DiagnosticError",
  NvimSettingsMuted = "Comment",
}

--- (Re-)link every settings-UI highlight group to its target. Idempotent and
--- cheap, safe to call on every colorscheme change and on every settings-UI
--- open.
function M.apply()
  for name, link in pairs(GROUPS) do
    vim.api.nvim_set_hl(0, name, { link = link, default = false })
  end
end

return M
