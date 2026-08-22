-- Inline test runner (neotest): results as signs in the sign column plus a
-- summary tree / output panel, instead of shelling out to `pytest`/`cargo
-- test` in a terminal and reading raw output. Keymaps live under the new
-- "T" (Test) leader group in lua/config/keymaps.lua.
--
-- Only the Python adapter is wired up for now -- pytest is the mandated
-- runner per ~/.claude/python.md, so the payoff is immediate and the
-- interpreter-resolution story is already solved (see the `python` option
-- below). Rust is deliberately left to rustaceanvim's own test runner
-- (`:RustLsp testables`, codelens "Run test" -- see lua/plugins/lsp.lua)
-- rather than adding neotest-rust on top of it: rustaceanvim already
-- generates its test configs from the real Cargo targets, and running two
-- competing test UIs for the same language would just be confusing. Add a
-- JS/TS adapter (neotest-jest/neotest-vitest) here the same way once it's
-- clear which test runner that side of a project actually uses.

return {
  {
    "nvim-neotest/neotest",
    -- No `keys`/`cmd` spec here on purpose: every keymap in this config goes
    -- through the central table in lua/config/keymaps.lua instead (its own
    -- header comment explains why -- single source of truth for
    -- which-key/legendary). Those entries' deferred `require("neotest")`
    -- calls are what actually triggers lazy.nvim's lazy-loading.
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
    },
    config = function()
      require("neotest").setup({
        adapters = {
          require("neotest-python")({
            -- `uv` is this project's package manager (~/.claude/python.md):
            -- for any root that has a uv.lock, route test runs through
            -- `uv run` instead of invoking the venv's python directly. That
            -- makes neotest sync the environment against the lockfile
            -- before every run, same as running `uv run pytest` by hand --
            -- plain venv-selector resolution (like dap-python's pythonPath
            -- in lua/plugins/dap.lua) only skips that sync check, it doesn't
            -- run a DIFFERENT interpreter, but the sync guarantee is worth
            -- having for a tool that's invoked this often. Falls back to
            -- venv-selector's own resolution for any non-uv project.
            -- `root` is neotest's own re-evaluation of the test root, not
            -- just Neovim's cwd, so this also works for multi-project setups.
            python = function(root)
              if vim.uv.fs_stat(vim.fs.joinpath(root, "uv.lock")) then
                return { "uv", "run", "--project", root, "python" }
              end
              local ok, venv_selector = pcall(require, "venv-selector")
              local python = ok and venv_selector.python()
              return (python and python ~= "") and python or nil
            end,
            dap = { justMyCode = false },
          }),
        },
      })
    end,
  },
}
