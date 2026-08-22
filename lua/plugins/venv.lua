-- Automatic Python virtual-environment detection/activation. Reachable via
-- <leader>lv / :VenvSelect (lua/config/keymaps.lua). Sets up LSP (basedpyright)
-- and terminal environment for whichever venv gets picked; the DAP debuggee
-- interpreter is wired separately in lua/plugins/dap.lua, since debugpy's own
-- adapter process must stay on Mason's install regardless of project venv.

return {
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
    ft = "python",
    -- Defaults re-detect on every Python LSP attach (require_lsp_activation),
    -- so switching project (e.g. via the <leader>fp project picker in
    -- lua/util/projects.lua) and opening a .py file there re-triggers
    -- detection automatically -- no options override needed here.
    opts = {},
  },
}
