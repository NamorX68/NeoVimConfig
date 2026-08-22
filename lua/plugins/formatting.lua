-- Formatting via conform.nvim. WHETHER to format on save is decided by
-- lua/config/autocmds.lua (gated by the persisted format_on_save setting);
-- this file only declares HOW to format each filetype.

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
        rust = { "rustfmt" },
        css = { "prettier" },
        scss = { "prettier" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
      },
      -- House line-length (120, matches ~/.claude/python.md and the global
      -- CLAUDE.md style rule) forced regardless of a project's own
      -- pyproject.toml/.prettierrc -- CLI flags win over both per each
      -- tool's own precedence rules, so this is a reliable global override,
      -- not just a fallback for projects that don't configure it themselves.
      -- Markdown is excluded below (function form, filetype-conditional):
      -- prettier's default proseWrap ("preserve") already leaves prose lines
      -- alone, and --print-width would still affect markdown TABLE column
      -- padding, fighting the 150-char prose limit in ../../.markdownlint.json
      -- for no benefit -- so markdown just keeps prettier's own default.
      formatters = {
        -- append_args, not prepend_args: conform's built-in ruff_fix/
        -- ruff_format base args already start with the `check`/`format`
        -- subcommand (e.g. `ruff check --fix ... -`), and `--line-length`
        -- is a subcommand option -- prepending would place it before the
        -- subcommand, which ruff rejects outright.
        ruff_fix = { append_args = { "--line-length", "120" } },
        ruff_format = { append_args = { "--line-length", "120" } },
        prettier = {
          -- prepend_args may be a function(self, ctx); ctx.buf gives us the
          -- filetype so this one formatter definition (shared by css/html/
          -- js/ts/json/yaml/markdown, see formatters_by_ft above) can opt
          -- markdown out instead of forcing a duplicate formatter entry.
          prepend_args = function(_, ctx)
            if vim.bo[ctx.buf].filetype == "markdown" then
              return {}
            end
            return { "--print-width", "120" }
          end,
        },
      },
    },
  },
}
