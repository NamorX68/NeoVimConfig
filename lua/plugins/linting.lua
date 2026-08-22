-- Supplementary linting via nvim-lint, used ONLY for linters that have no
-- good LSP mode: Python/JS/TS linting is already covered by LSP diagnostics
-- (ruff-as-LSP, eslint-as-LSP in lua/plugins/lsp.lua), which additionally
-- provide code-action quick fixes that a standalone linter cannot.

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "InsertLeave" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        dockerfile = { "hadolint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        markdown = { "markdownlint" },
      }

      -- House style (see .markdownlint.json next to this config: MD013 line
      -- length raised from markdownlint's 80-char default to 150) applied to
      -- every markdown file regardless of which project is open -- most
      -- repos don't ship their own .markdownlint.json, and 80 is too strict
      -- for prose.
      lint.linters.markdownlint.args = {
        "--config",
        vim.fs.joinpath(vim.fn.stdpath("config"), ".markdownlint.json"),
        "--stdin",
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = function(args)
          if not require("util.lang").is_enabled(vim.bo[args.buf].filetype) then
            return
          end
          lint.try_lint()
        end,
      })
    end,
  },
}
