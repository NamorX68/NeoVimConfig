-- Floating/split terminal helpers built on toggleterm.nvim: a plain shell
-- plus two dedicated instances for the external TUI tools that provide
-- "graphical" Git/Docker (lazygit/lazydocker), each with persistent toggle
-- state. Referenced from lua/config/keymaps.lua as require("util.terminal")
-- -- lives outside lua/plugins/ for the same reason as lua/util/theme.lua
-- and lua/util/lang.lua: lazy.nvim's `{ import = "plugins" }` treats every
-- file directly under lua/plugins/ as a plugin-spec module, not a plain
-- helper module.

local M = {}

local Terminal = require("toggleterm.terminal").Terminal

local shell = Terminal:new({ direction = "float", hidden = true })
local lazygit = Terminal:new({
  cmd = "lazygit",
  direction = "float",
  hidden = true,
  float_opts = { border = "curved" },
})
local lazydocker = Terminal:new({
  cmd = "lazydocker",
  direction = "float",
  hidden = true,
  float_opts = { border = "curved" },
})

function M.float()
  shell:toggle()
end

function M.horizontal()
  Terminal:new({ direction = "horizontal" }):toggle()
end

function M.vertical()
  Terminal:new({ direction = "vertical" }):toggle()
end

--- Toggle a floating LazyGit TUI (requires the `lazygit` CLI on PATH).
function M.lazygit()
  lazygit:toggle()
end

--- Toggle a floating LazyDocker TUI (requires the `lazydocker` CLI on PATH).
function M.lazydocker()
  lazydocker:toggle()
end

return M
