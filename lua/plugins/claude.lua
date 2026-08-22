-- Claude Code IDE integration (MCP/WebSocket protocol, the same basis the
-- official VS Code/JetBrains extensions use). Opens as a right-hand split
-- with a native diff view for proposed changes. Keymaps live under the "a"
-- (AI) leader group in lua/config/keymaps.lua, not here, matching how
-- lua/plugins/dap.lua keeps adapter wiring separate from keymaps.
--
-- Requires the `claude` CLI to already be installed and authenticated on
-- this machine -- the plugin only connects to it, it does not ship it.

return {
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    opts = {
      terminal = {
        split_side = "right",
        split_width_percentage = 0.30,
        provider = "auto", -- prefers snacks.nvim, falls back to native :terminal
        auto_close = true,
      },
    },
    config = true,
  },
}
