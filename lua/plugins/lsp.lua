-- LSP stack: mason.nvim installs/manages servers and standalone tools,
-- nvim-lspconfig ships each server's default `vim.lsp.config()` table (the
-- native Neovim 0.11+ LSP-config API -- nvim-lspconfig's role today is
-- primarily to provide these defaults, which this file layers project
-- capabilities/settings on top of before calling `vim.lsp.enable()`).
--
-- Rust is the one exception: it is owned entirely by rustaceanvim (see
-- below), which manages its own rust-analyzer client lifecycle, including
-- richer hover/code-lens/DAP wiring than plain lspconfig would give it.

return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = { ui = { border = "rounded" } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Server name -> vim.lsp.config() overrides. Keys double as the
      -- mason-lspconfig ensure_installed list.
      local servers = {
        basedpyright = {},
        ruff = {
          -- basedpyright already provides hover; without this, two hover
          -- popups race and ruff (whose hover is much sparser) usually wins.
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
          -- House line-length (120, matches ~/.claude/python.md's ruff
          -- standard) for E501 if a project ever enables it -- E501 isn't in
          -- ruff's default rule selection, so this mostly future-proofs
          -- diagnostics. The formatter (lua/plugins/formatting.lua) is what
          -- actually enforces this on save; ruff's own tracker shows this
          -- LSP setting isn't reliably honored for formatting requests.
          init_options = {
            settings = { lineLength = 120 },
          },
        },
        cssls = {},
        html = {},
        ts_ls = {},
        eslint = {},
        clangd = {},
        dockerls = {},
        docker_compose_language_service = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              diagnostics = { globals = { "vim" } },
            },
          },
        },
      }

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = vim.tbl_keys(servers),
        -- Several mason packages installed purely as formatters/linters
        -- below (stylua, prettier, ...) ship their OWN optional LSP mode
        -- and would otherwise get silently auto-enabled by mason-lspconfig
        -- just because a matching lspconfig default exists. `vim.lsp.enable`
        -- below is kept as the single explicit source of truth instead.
        automatic_enable = false,
      })
      local tool_installer = require("mason-tool-installer")
      tool_installer.setup({
        ensure_installed = {
          -- Mirrors `servers` above by mason PACKAGE name (which differs
          -- from the lspconfig server name for several of these). This is
          -- deliberately redundant with mason-lspconfig's own
          -- ensure_installed: that mechanism silently no-ops in headless
          -- Neovim (`mason-lspconfig/init.lua` gates it behind
          -- `not platform.is_headless`), so mason-tool-installer is kept as
          -- the single reliable install path for every server/tool below,
          -- regardless of how Neovim is launched.
          "basedpyright",
          "css-lsp",
          "html-lsp",
          "typescript-language-server",
          "eslint-lsp",
          "dockerfile-language-server",
          "docker-compose-language-service",
          "lua-language-server",
          "rust-analyzer", -- consumed by rustaceanvim, not by lspconfig
          "codelldb", -- DAP adapter for Rust/C/C++, see lua/plugins/dap.lua
          "stylua",
          "prettier",
          "clang-format",
          "shfmt",
          "hadolint",
          "shellcheck",
          "markdownlint",
        },
      })
      -- setup() only registers settings; it does NOT install anything on
      -- its own (unlike mason-lspconfig's ensure_installed). run_on_start()
      -- must be called explicitly to actually kick off the installs.
      tool_installer.run_on_start()

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      for name, server_opts in pairs(servers) do
        vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = capabilities }, server_opts))
      end
      vim.lsp.enable(vim.tbl_keys(servers))

      -- Reflect the persisted per-language toggles (Konfigurationsmaske,
      -- see lua/settings/ui.lua) by enabling/disabling each language's LSP
      -- clients.
      local lang = require("util.lang")
      local function apply_language_settings(languages)
        for language, server_names in pairs(lang.LANGUAGE_TO_LSP_SERVERS) do
          for _, server_name in ipairs(server_names) do
            vim.lsp.enable(server_name, languages[language] ~= false)
          end
        end
        -- rustaceanvim doesn't go through vim.lsp.enable() (see
        -- lua/util/lang.lua), so disabling it here just stops any already
        -- running rust-analyzer client. Re-enabling has no code path to
        -- restart it automatically -- reopening the *.rs buffer is what
        -- reattaches, which is documented on the language row itself.
        if languages.rust == false then
          for _, client in ipairs(vim.lsp.get_clients({ name = "rust-analyzer" })) do
            client:stop()
          end
        end
      end
      -- Apply once immediately: vim.lsp.enable() above just turned every
      -- server on unconditionally, so a language disabled in a PREVIOUS
      -- session (already on disk) must be re-disabled right away, not only
      -- the next time the settings UI calls state.set("languages", ...).
      apply_language_settings(require("settings").state.get().languages)
      require("settings").state.register("languages", apply_language_settings)

      -- Reflect the persisted inlay-hints toggle on every currently loaded
      -- buffer (new buffers pick it up via the LspAttach autocmd instead,
      -- see lua/config/autocmds.lua).
      require("settings").state.register("inlay_hints", function(enabled)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            pcall(vim.lsp.inlay_hint.enable, enabled, { bufnr = buf })
          end
        end
      end)
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Correct vim.uv completion/type info while editing this very config.
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
    init = function()
      -- The whole vim.g.rustaceanvim table is set here in one place
      -- (including its DAP adapter) because rustaceanvim reads it as a
      -- unit when it first attaches to a *.rs buffer; splitting it across
      -- lsp.lua and dap.lua would risk one half silently overwriting the
      -- other depending on plugin load order.
      vim.g.rustaceanvim = {
        server = {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
        },
        dap = {
          adapter = function()
            local mason_registry = require("mason-registry")
            local codelldb = mason_registry.get_package("codelldb")
            local extension_path = codelldb:get_install_path() .. "/extension/"
            local codelldb_path = extension_path .. "adapter/codelldb"
            local liblldb_path = extension_path .. "lldb/lib/liblldb"
            liblldb_path = liblldb_path .. (vim.fn.has("mac") == 1 and ".dylib" or ".so")
            return require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path)
          end,
        },
      }
    end,
  },
}
