-- Runtime colorscheme switching for the settings UI ("Konfigurationsmaske").
--
-- Deliberately lives OUTSIDE lua/plugins/ -- lazy.nvim's `{ import = "plugins" }`
-- (see lua/config/lazy.lua) recursively loads every module under lua/plugins/
-- expecting each one to `return` a list of plugin specs; a plain helper
-- module there would be misinterpreted as a broken spec.
--
-- lua/plugins/ui.lua declares all 5 colorscheme plugins with `lazy = false`
-- but no `opts`/`config` -- THIS module is the single place that calls each
-- theme's setup() and activates one via `vim.cmd.colorscheme`, so switching
-- at runtime (colorscheme, variant, or transparency) always goes through
-- the same code path as the initial startup application.

local M = {}

--- One entry per colorscheme selectable in the settings UI.
--- `opts(state)` builds that theme's setup() table from persisted state.
--- `colorscheme_name(state)` returns the exact name passed to `:colorscheme`.
local THEMES = {
  catppuccin = {
    setup_module = "catppuccin",
    variants = { "latte", "frappe", "macchiato", "mocha" },
    default_variant = "mocha",
    opts = function(state)
      return {
        flavour = state.colorscheme_variant,
        transparent_background = state.background_transparency,
        integrations = {
          blink_cmp = true,
          gitsigns = true,
          telescope = true,
          treesitter = true,
          neotree = true,
          noice = true,
          which_key = true,
          indent_blankline = { enabled = true },
          mason = true,
          native_lsp = { enabled = true },
          dap = true,
          dap_ui = true,
        },
      }
    end,
    colorscheme_name = function() return "catppuccin" end,
  },
  tokyonight = {
    setup_module = "tokyonight",
    variants = { "storm", "moon", "night", "day" },
    default_variant = "storm",
    opts = function(state)
      return { style = state.colorscheme_variant, transparent = state.background_transparency }
    end,
    colorscheme_name = function() return "tokyonight" end,
  },
  gruvbox = {
    setup_module = "gruvbox",
    variants = { "dark", "light" },
    default_variant = "dark",
    opts = function(state)
      return { contrast = "hard", transparent_mode = state.background_transparency }
    end,
    colorscheme_name = function() return "gruvbox" end,
  },
  kanagawa = {
    setup_module = "kanagawa",
    variants = { "wave", "dragon", "lotus" },
    default_variant = "wave",
    opts = function(state)
      return { theme = state.colorscheme_variant, transparent = state.background_transparency }
    end,
    colorscheme_name = function(state) return "kanagawa-" .. state.colorscheme_variant end,
  },
  github = {
    setup_module = "github-theme",
    variants = { "dark", "light", "dark_dimmed", "dark_high_contrast" },
    default_variant = "dark",
    opts = function() return {} end,
    colorscheme_name = function(state) return "github_" .. state.colorscheme_variant end,
  },
  -- The bold/high-contrast option (neon-on-black) requested alongside the
  -- other visual-polish work -- everything else here leans muted/pastel.
  cyberdream = {
    setup_module = "cyberdream",
    variants = { "default", "light", "muted" },
    default_variant = "default",
    opts = function(state)
      return { variant = state.colorscheme_variant, transparent = state.background_transparency }
    end,
    colorscheme_name = function() return "cyberdream" end,
  },
}

M.THEMES = THEMES

--- Re-run setup() for the currently active theme and activate it.
--- Safe to call repeatedly (e.g. every time a relevant setting changes).
function M.apply()
  local state = require("settings").state.get()
  local entry = THEMES[state.colorscheme]
  if not entry then
    vim.notify("util.theme: unknown colorscheme " .. tostring(state.colorscheme), vim.log.levels.WARN)
    return
  end

  -- Fall back to this theme's own default variant if the persisted variant
  -- doesn't belong to it (e.g. switching from catppuccin's "mocha" to
  -- tokyonight, which has no "mocha" style).
  if not vim.tbl_contains(entry.variants, state.colorscheme_variant) then
    state.colorscheme_variant = entry.default_variant
  end

  -- gruvbox.nvim (unlike the other 4 themes) reads its light/dark palette
  -- from `vim.o.background` rather than from its own setup() options, so
  -- switching its variant would otherwise have no visible effect.
  vim.o.background = state.colorscheme_variant == "light" and "light" or "dark"

  local ok, mod = pcall(require, entry.setup_module)
  if ok then
    mod.setup(entry.opts(state))
  end
  vim.cmd.colorscheme(entry.colorscheme_name(state))

  -- The settings UI's own highlight groups link to this theme's groups
  -- (TabLineSel, Title, ...), so they need re-deriving on every switch too.
  -- See lua/settings/highlights.lua for why this is a direct call rather
  -- than a second state.register() on these same keys.
  require("settings.highlights").apply()
end

-- Any of these three settings changing means the active theme must be
-- reconfigured and reapplied.
require("settings").state.register("colorscheme", M.apply)
require("settings").state.register("colorscheme_variant", M.apply)
require("settings").state.register("background_transparency", M.apply)

return M
