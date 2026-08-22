-- Diagnostic DISPLAY STYLE -- how errors/warnings show up in a buffer, as
-- opposed to lua/plugins/linting.lua (which linters run) or the base cosmetics
-- (signs/underline/severity_sort) set once in lua/config/options.lua.
--
-- Four selectable styles, persisted as settings.state.diagnostics_style and
-- switchable via the "Diagnostics style" row in the settings UI
-- (lua/settings/ui.lua) or the <leader>lI cycle keymap:
--   virtual_text  -- Neovim's classic text-behind-every-line renderer
--   current_line  -- same renderer, but only for the line the cursor is on
--   virtual_lines -- native Neovim 0.10+ renderer: message on its own line below
--   inline        -- tiny-inline-diagnostic.nvim: compact floating box, cursor line only
--
-- Exactly one of these is ever active: apply_style() below is the single
-- place that flips vim.diagnostic.config's virtual_text/virtual_lines AND
-- the plugin's enable/disable, so they can never both render at once.

return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000, -- README-recommended: get its highlight groups defined early
    config = function()
      local diag = require("tiny-inline-diagnostic")
      diag.setup({ preset = "modern" })
      -- The plugin never touches vim.diagnostic.config itself (per its
      -- README, virtual_text must be disabled manually to avoid double
      -- rendering) -- apply_style() below is what actually turns it on.
      diag.disable()

      local state = require("settings").state

      local function apply_style(style)
        if style == "inline" then
          vim.diagnostic.config({ virtual_text = false, virtual_lines = false })
          diag.enable()
          return
        end
        diag.disable()
        if style == "virtual_lines" then
          vim.diagnostic.config({ virtual_text = false, virtual_lines = true })
        elseif style == "current_line" then
          vim.diagnostic.config({ virtual_text = { current_line = true }, virtual_lines = false })
        else -- "virtual_text", and a fallback for any unrecognized/legacy value
          vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
        end
      end

      -- Apply once immediately: this config() only just turned the plugin on
      -- (disable() above), so the persisted style from a previous session
      -- must be applied right away, not only on the next settings change --
      -- same "apply once immediately" pattern as lsp.lua's language toggles.
      apply_style(state.get().diagnostics_style)
      state.register("diagnostics_style", apply_style)
    end,
  },
}
