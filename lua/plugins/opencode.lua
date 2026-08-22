-- Opencode AI CLI integration (nickjvandyke/opencode.nvim) -- editor-aware
-- pair programming with a local/self-hosted LLM, the same shape of
-- integration lua/plugins/claude.lua gives Claude Code: automatic
-- buffer/selection/diagnostics context, a native diff view for proposed
-- edits (with its own buffer-local da/dr/dp/do/[c/]c keymaps, left at
-- defaults like git-conflict.nvim's -- see lua/plugins/git.lua), and
-- multi-file support. Keymaps live under the "o" (Opencode) leader group in
-- lua/config/keymaps.lua, not here, matching every other plugin here.
--
-- Requires the `opencode` CLI to already be installed and configured
-- (pointed at whichever local LLM backend you're using) -- this plugin only
-- connects to/spawns it, it does not ship it.
--
-- Config goes through vim.g.opencode_opts (a global var the plugin reads
-- lazily), not a setup() call -- that's this plugin's own convention, set
-- in init() so it's in place before the plugin's first use regardless of
-- when lazy.nvim actually loads it.

return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = { "folke/snacks.nvim" },
    init = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- lua/util/opencode.lua's toggle, not opencode.nvim's own default
          -- (a plain left vsplit) -- see that file for why both this
          -- auto-start hook and the manual <leader>ot keymap share it.
          start = require("util.opencode").toggle,
        },
      }
    end,
  },
}
