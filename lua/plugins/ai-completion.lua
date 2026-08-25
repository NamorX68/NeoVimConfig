-- Inline AI code completion (ghost text), separate from the LSP-driven
-- completion menu in lua/plugins/completion.lua. Supermaven is chosen for
-- its genuinely unlimited free tier and low-latency suggestions; it renders
-- as virtual text rather than a blink.cmp source, so it composes with
-- blink.cmp's Tab/snippet-jump fallback chain instead of competing with it.
--
-- First use requires linking an account: run :SupermavenUse and follow the
-- browser prompt (free, no credit card).

return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-j>",
      },
    },
  },
}
