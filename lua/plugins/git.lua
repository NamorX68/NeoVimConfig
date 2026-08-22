-- Inline Git information (hunk signs, blame) and merge-conflict resolution.
-- The "graphical" Git UI itself is lazygit, launched in a floating terminal
-- -- see lua/util/terminal.lua and the <leader>gg keymap in
-- lua/config/keymaps.lua.

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      current_line_blame = false,
      current_line_blame_opts = { delay = 300 },
    },
  },

  -- Highlights <<<<<<< / ======= / >>>>>>> merge-conflict markers and gives
  -- buffer-local resolution keymaps (co/ct/cb/c0 = ours/theirs/both/none,
  -- [x/]x = prev/next conflict) -- upstream defaults, left as-is like
  -- neo-tree's own file-op keys (lua/plugins/neotree.lua) since they already
  -- cover everything and only ever activate in a buffer that actually has
  -- conflict markers. <leader>gL (lua/config/keymaps.lua) is the one
  -- supplementary addition: lists every conflict across the repo at once.
  { "akinsho/git-conflict.nvim", version = "*", event = { "BufReadPre", "BufNewFile" }, config = true },
}
