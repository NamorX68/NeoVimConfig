-- A no-modifier-holding "window mode" for moving between and resizing
-- splits. Lives outside lua/plugins/ for the same reason as
-- lua/util/theme.lua -- lazy.nvim's `{ import = "plugins" }` would otherwise
-- misinterpret this plain helper module as a broken plugin spec.
--
-- Why this exists: <C-h/j/k/l> (lua/config/keymaps.lua) require HOLDING a
-- modifier, which is uncomfortable on a split keyboard using hold-based
-- home-row mods. Window mode instead needs only plain taps: <leader>W enters
-- it, h/j/k/l move focus, +/-/</> resize the current window, and any other
-- key (or a short idle timeout) exits back to normal mode.
--
-- Implementation note: this uses temporary global keymaps rather than a
-- vim.fn.getcharstr() loop, because getcharstr() blocks the event loop
-- between keypresses (no redraw, no statusline update) and would need its
-- own re-implementation of <Esc>/timeout handling. Plain vim.keymap.set +
-- vim.keymap.del composes with Neovim's own input handling for free. It is
-- safe to unconditionally `del` (rather than snapshot+restore) every temp
-- key on exit: none of h/j/k/l/+/-/</>/q are bound in normal mode anywhere
-- else in this config (see lua/config/keymaps.lua's M.base/M.leader).

local M = {}

local ACTIONS = {
  h = "<C-w>h",
  j = "<C-w>j",
  k = "<C-w>k",
  l = "<C-w>l",
  ["+"] = "<C-w>+",
  ["-"] = "<C-w>-",
  ["<"] = "<C-w><",
  [">"] = "<C-w>>",
}

local HINT = "-- WINDOW MODE -- h/j/k/l move  +/-/</> resize  q/Esc exit"

local active = false

--- Leave window mode: clear every temporary keymap and the status hint.
function M.exit()
  if not active then
    return
  end
  active = false
  for key in pairs(ACTIONS) do
    pcall(vim.keymap.del, "n", key)
  end
  pcall(vim.keymap.del, "n", "q")
  pcall(vim.keymap.del, "n", "<Esc>")
  vim.api.nvim_echo({ { "", "None" } }, false, {}) -- clear the hint line
end

--- Enter window mode: bind h/j/k/l/+/-/</> to repeat without holding a
--- modifier, and q/<Esc> (or any further <leader>W press) to exit.
function M.enter()
  if active then
    return
  end
  active = true

  for key, rhs in pairs(ACTIONS) do
    vim.keymap.set("n", key, rhs, { desc = "Window mode: " .. rhs })
  end
  vim.keymap.set("n", "q", M.exit, { desc = "Exit window mode" })
  vim.keymap.set("n", "<Esc>", M.exit, { desc = "Exit window mode" })

  -- "Title" rather than one of the settings-UI's own highlight groups
  -- (lua/settings/highlights.lua) -- this module has no reason to depend on
  -- that one, and "Title" is guaranteed to exist in every colorscheme.
  vim.api.nvim_echo({ { HINT, "Title" } }, false, {})
end

--- Toggle window mode on/off -- what <leader>W is actually bound to, so
--- pressing it again exits instead of doing nothing.
function M.toggle()
  if active then
    M.exit()
  else
    M.enter()
  end
end

return M
