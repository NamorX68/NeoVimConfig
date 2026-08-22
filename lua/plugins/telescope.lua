-- Fuzzy finder. Actual keymaps (<leader>ff, <leader>fg, ...) live in the
-- central table in lua/config/keymaps.lua; requiring "telescope.builtin"
-- from there triggers lazy.nvim's module-based lazy-loading on its own, so
-- no `keys` spec is needed here.

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          mappings = {
            i = { ["<esc>"] = require("telescope.actions").close },
          },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })
      -- fzf-native gives Telescope a much faster native sorter; ui-select
      -- routes vim.ui.select() (e.g. LSP code action picker) through
      -- Telescope's UI instead of the plain built-in one.
      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
    end,
  },
}
