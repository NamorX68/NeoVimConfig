-- Minimal project switcher: a Telescope picker over a short, hand-maintained
-- list of known project root directories. Lives outside lua/plugins/ for the
-- same reason as lua/util/theme.lua. Reachable via <leader>fp and <D-o>
-- (lua/config/keymaps.lua).
--
-- Deliberately small in scope: this does not scan the filesystem or manage
-- multi-root workspaces -- it changes cwd (:tcd) to a known project and
-- restores its persistence.nvim session (lua/plugins/editor.lua), the same
-- session mechanism already used for single-project work. Add your own
-- project paths to M.roots below.

local M = {}

--- Edit this list to add your own projects.
---@type string[]
M.roots = {
  vim.fn.stdpath("config"), -- this Neovim config itself, always available
}

--- Open the project picker. Selecting an entry changes the working
--- directory and tries to restore that directory's persistence.nvim session.
function M.picker()
  local roots = vim.tbl_filter(function(path) return vim.fn.isdirectory(path) == 1 end, M.roots)
  if #roots == 0 then
    vim.notify("util.projects: no valid entries in M.roots", vim.log.levels.WARN)
    return
  end

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Projects",
      finder = require("telescope.finders").new_table({ results = roots }),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        require("telescope.actions").select_default:replace(function()
          local selection = require("telescope.actions.state").get_selected_entry()
          require("telescope.actions").close(prompt_bufnr)
          vim.cmd.tcd(selection[1])
          pcall(function() require("persistence").load() end)
        end)
        return true
      end,
    })
    :find()
end

return M
