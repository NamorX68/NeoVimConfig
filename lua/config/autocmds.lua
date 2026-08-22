-- Editor-wide autocommands. LSP-specific buffer-local keymaps are attached
-- here (via LspAttach) rather than in lua/config/keymaps.lua, because they
-- only make sense once a client has actually attached to the buffer.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlight yanked text.
autocmd("TextYankPost", {
  group = augroup("highlight-yank", { clear = true }),
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Restore cursor position when reopening a file.
autocmd("BufReadPost", {
  group = augroup("restore-cursor", { clear = true }),
  desc = "Restore cursor to last known position",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close throwaway filetypes with a single `q`.
autocmd("FileType", {
  group = augroup("close-with-q", { clear = true }),
  desc = "Close utility windows with q",
  pattern = { "help", "qf", "lspinfo", "checkhealth", "man", "notify" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})

-- Auto-create parent directories on save (e.g. writing src/new/module.py in
-- a directory that doesn't exist yet).
autocmd("BufWritePre", {
  group = augroup("auto-mkdir", { clear = true }),
  desc = "Create parent directories on save",
  callback = function(args)
    local dir = vim.fn.fnamemodify(args.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Format-on-save, gated by the persisted setting (global + per-filetype
-- override). conform.nvim itself is set up in lua/plugins/formatting.lua;
-- this hook only decides WHETHER to call it.
autocmd("BufWritePre", {
  group = augroup("format-on-save", { clear = true }),
  desc = "Format buffer on save when enabled in settings",
  callback = function(args)
    local filetype = vim.bo[args.buf].filetype
    if not require("util.lang").is_enabled(filetype) then
      return
    end
    local settings = require("settings").state.get()
    local per_ft = settings.format_on_save_filetype[filetype]
    local enabled = per_ft
    if enabled == nil then
      enabled = settings.format_on_save
    end
    if not enabled then
      return
    end
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = args.buf, lsp_fallback = true, timeout_ms = 1000 })
    end
  end,
})

-- Supplementary LSP keymaps and inlay hints, applied per-buffer once a
-- client attaches. Neovim 0.11+ ships `grn`/`gra`/`grr`/`gri`/`gO`/`gs` as
-- core defaults already -- these are intentionally left untouched. This
-- autocmd only adds what core does NOT provide by default.
autocmd("LspAttach", {
  group = augroup("lsp-attach", { clear = true }),
  desc = "Buffer-local LSP keymaps and inlay hints",
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    map("n", "K", vim.lsp.buf.hover, "LSP hover")
    map("n", "gd", vim.lsp.buf.definition, "Goto definition")
    map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
    map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
    map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")

    if client and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(require("settings").state.get().inlay_hints, { bufnr = buf })
    end
  end,
})

-- Re-check external file changes when focus returns to Neovim.
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime", { clear = true }),
  desc = "Check for external file changes",
  command = "checktime",
})
