-- File explorer sidebar. Default file-operation keymaps inside the tree
-- window (a=add, A=add_directory, d=delete, r=rename, c=copy, y=copy to
-- clipboard, x=cut to clipboard, p=paste, ? for the full help popup) are
-- intentionally left at neo-tree's own defaults rather than redefined here
-- -- they already fully satisfy "alle nötigen Befehle" and redefining them
-- risks silently dropping one.

-- Claude Code integration (lua/plugins/claude.lua): add the file under the
-- cursor -- or, with a visual multi-select (V, move, then <leader>as), every
-- file spanned by the selection -- to Claude's context via ClaudeCodeTreeAdd.
-- Same "as" key as the visual-mode "send selection" mapping in
-- lua/config/keymaps.lua; that one can't also cover this case since it isn't
-- scoped to a filetype.
--
-- This is a plain FileType autocmd instead of a window.mappings entry above
-- (claudecode.nvim's recommended way to wire this) for a subtle reason:
-- neo-tree only auto-registers a Visual-mode counterpart for mappings given
-- as a STRING naming one of ITS OWN commands with a matching "<name>_visual"
-- entry (see neo-tree's set_buffer_mappings, which only builds `vfunc` in
-- that string branch) -- a raw Lua function, which is the only way to call an
-- external plugin command from window.mappings, never gets a Visual-mode
-- keymap at all, so multi-select silently wouldn't fire. Worse, neo-tree's
-- OWN Visual-mode wrapper (when it does apply) sends a real <Esc> and only
-- resolves the selected nodes in a scheduled callback afterwards -- by then
-- mode() has already reverted to "n", which breaks ClaudeCodeTreeAdd's own
-- multi-select detection (it inspects vim.fn.mode() itself). A raw
-- "<cmd>...<cr>" keymap set directly in Visual/Select mode ("x") sidesteps
-- both problems: <cmd> mappings run without leaving the current mode, so
-- mode() still reports "v"/"V"/CTRL-V when ClaudeCodeTreeAdd inspects it.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  group = vim.api.nvim_create_augroup("neotree-claude-add", { clear = true }),
  callback = function(args)
    vim.keymap.set({ "n", "x" }, "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
      buffer = args.buf,
      silent = true,
      desc = "Add file(s) to Claude context",
    })
  end,
})

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      close_if_last_window = true,
      popup_border_style = "rounded",
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = { hide_dotfiles = false, hide_gitignored = false },
      },
      default_component_configs = {
        git_status = {
          symbols = { added = "✚", modified = "", deleted = "✖", renamed = "" },
        },
      },
      window = {
        mappings = {
          -- Explicit instead of implicit via neo-tree's own defaults: `q` is
          -- already the upstream default (close_window), but pinned and
          -- documented here so it doesn't have to be rediscovered in
          -- neo-tree's source. <Esc> is a second, even more obvious escape
          -- hatch out of the tree window.
          ["q"] = "close_window",
          ["<esc>"] = "close_window",
          -- <leader>as (add file to Claude context) is deliberately NOT
          -- defined here -- see the FileType autocmd below for why.
        },
      },
    },
  },
}
