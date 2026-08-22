-- Completion engine. blink.cmp is chosen for native LSP capabilities and
-- speed, with its own built-in snippet engine (no LuaSnip dependency) --
-- friendly-snippets is used purely as the snippet-body library.

return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = true },
        menu = { auto_show = true },
        list = { selection = { preselect = true } },
      },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },
}
