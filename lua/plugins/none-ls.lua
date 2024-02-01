return {
  "nvimtools/none-ls.nvim",
  config = function()
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.black.with({
          extra_args = { "--line-length=130" }
        }),
        null_ls.builtins.formatting.isort,
        null_ls.builtins.diagnostics.ruff,
        null_ls.builtins.formatting.rustfmt,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.prettier,
      },
    })

    vim.keymap.set("n", "<leader>ff", vim.lsp.buf.format, {})
  end,
}
