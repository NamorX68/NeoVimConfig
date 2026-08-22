-- toggleterm.nvim plugin declaration. The actual reusable Terminal
-- instances (plain shell, lazygit, lazydocker) live in lua/util/terminal.lua
-- and are what lua/config/keymaps.lua calls into.

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm",
    opts = {
      open_mapping = [[<c-\>]],
      shade_terminals = true,
      direction = "float",
      float_opts = { border = "curved" },
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
    },
  },
}
