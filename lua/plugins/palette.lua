-- Command palette (VS Code Ctrl+Shift+P equivalent), bound to <leader><leader>
-- in lua/config/keymaps.lua.
--
-- legendary.nvim's `extensions.which_key.auto_register` looked like the
-- obvious way to feed it every keymap, but it monkey-patches the deprecated
-- which-key v2 `wk.register()` function -- which-key v3 (configured in
-- lua/plugins/ui.lua) only ever calls `wk.add()`, so that bridge silently
-- never fires and the palette would stay empty. Instead, this file builds
-- legendary's item list directly from lua/config/keymaps.lua, as
-- DESCRIPTION-ONLY items (no second positional element -- see
-- legendary's own `Keymap:parse()`, which special-cases `tbl[2] == nil` as
-- "description-only" and skips `vim.keymap.set` for it). That gives the
-- palette full search/display without ever double-binding a key that
-- lua/config/keymaps.lua's own M.apply() already bound.
--
-- which-key.nvim itself is configured in lua/plugins/ui.lua (it is part of
-- the general UI shell); this file only adds legendary on top of it.

return {
  {
    "mrjones2014/legendary.nvim",
    cmd = "Legendary",
    dependencies = { "folke/which-key.nvim" },
    opts = function()
      local keymaps = require("config.keymaps")
      local items = {}
      for _, maps in ipairs({ keymaps.base, keymaps.leader, keymaps.mac }) do
        for _, map in ipairs(maps) do
          table.insert(items, { map[1], description = map.desc, mode = map.mode or "n" })
        end
      end
      return { keymaps = items }
    end,
  },
}
