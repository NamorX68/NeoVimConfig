-- Colorschemes and the general UI shell: statusline, buffer tabs, indent
-- guides, start dashboard, centered cmdline/messages, LSP progress spinner,
-- and which-key (the discoverability layer for the <leader> keymap groups
-- defined in lua/config/keymaps.lua).
--
-- All 6 colorschemes below are intentionally `lazy = false, priority = 1000`
-- with NO `opts`/`config` -- lua/util/theme.lua is the single place that
-- calls each theme's setup() and activates one, so runtime switching from
-- the settings UI always goes through the same code path as startup.

-- Manual and automatic ways back to the start screen (snacks.nvim's
-- dashboard, configured below, only opens itself once on VimEnter):
--   :Dashboard / <leader>cd (lua/config/keymaps.lua) -- reopen anytime
--   BufDelete autocmd -- reopens itself once the last real (named, listed,
--   unmodified) buffer closes and only an empty scratch buffer is left in a
--   single window, mirroring what closing the last tab does in a GUI IDE.
--   Guarded so it never fires while quitting or while a buffer with unsaved
--   changes/another window is still around.
vim.api.nvim_create_user_command("Dashboard", function() Snacks.dashboard() end, { desc = "Open the start screen" })

vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("dashboard-reopen", { clear = true }),
  callback = function()
    vim.schedule(function()
      if not (Snacks and Snacks.dashboard) then
        return
      end
      if vim.v.exiting ~= vim.NIL then
        return -- don't open mid-:qa/:qa!
      end
      if #vim.api.nvim_list_wins() ~= 1 then
        return -- something else (neo-tree, a split, ...) is still open
      end
      local buf = vim.api.nvim_get_current_buf()
      local other_listed = vim.tbl_filter(function(b) return b ~= buf and vim.bo[b].buflisted end, vim.api.nvim_list_bufs())
      if #other_listed > 0 then
        return
      end
      if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
        return -- leftover buffer has a name or unsaved changes -- not the "everything closed" case
      end
      Snacks.dashboard()
    end)
  end,
})

-- Attaches nvim-navic to every LSP client that can supply document symbols,
-- powering the winbar breadcrumbs configured on lualine.nvim below. Kept
-- top-level (not inside nvim-navic's own config()) so it exists before the
-- very first LspAttach -- see that plugin entry for the full reasoning.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("navic-attach", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/documentSymbol") then
      require("nvim-navic").attach(client, args.buf)
    end
  end,
})

-- One random line shown on the dashboard beneath the keys (see the
-- dashboard's `sections` below). Self-referential on purpose -- pulled from
-- this config's own keymaps rather than generic quotes, so it's actually
-- useful and never goes stale in a way that would need separate upkeep from
-- lua/config/keymaps.lua (a wrong tip here is caught the next time it's read).
local DASHBOARD_TIPS = {
  "Tip: gd / gD jump to a symbol's definition / declaration.",
  "Tip: grr shows LSP references in Trouble.",
  "Tip: s / S (flash.nvim) jump anywhere on screen by typed label.",
  "Tip: <leader>fs opens grug-far for project-wide search & replace.",
  "Tip: <leader>gg opens LazyGit in a floating terminal.",
  "Tip: <leader>xt lists TODO/FIXME comments in Trouble.",
  "Tip: <leader>ld generates a docstring for the function under the cursor.",
  "Tip: <leader>cs opens the settings UI (Konfigurationsmaske).",
  "Tip: <leader><leader> opens the command palette.",
  "Tip: <leader>Tt runs the nearest test under the cursor.",
}

return {
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
  { "projekt0n/github-nvim-theme", lazy = false, priority = 1000 },
  { "scottmckendry/cyberdream.nvim", lazy = false, priority = 1000 },

  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Breadcrumbs (VS Code/PyCharm-style "Class > method" path at the top of
  -- the window), rendered into lualine's winbar section below. lazy = true
  -- (no event/cmd/ft) is intentional: nothing here ever calls
  -- `require("nvim-navic")` at startup, only the LspAttach autocmd below
  -- does, on demand, the same lazy-require pattern used for
  -- tiny-inline-diagnostic.nvim in lua/plugins/diagnostics.lua. That
  -- autocmd has to be registered eagerly (top-level, not inside navic's own
  -- config()) since it must already exist before the FIRST LspAttach fires.
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    opts = { separator = "  ", highlight = true, depth_limit = 5 },
    config = function(_, opts) require("nvim-navic").setup(opts) end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto", -- follows whichever colorscheme is active, all 6 are supported
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { { require("util.venv").status }, "diagnostics", "encoding", "filetype" },
      },
      -- Breadcrumbs only render where nvim-navic actually attached (i.e. an
      -- LSP with documentSymbolProvider is active for that buffer) -- empty
      -- everywhere else (neo-tree, the dashboard, terminals, ...), so this
      -- never needs its own filetype denylist.
      winbar = {
        lualine_c = {
          {
            function() return require("nvim-navic").get_location() end,
            cond = function()
              local ok, navic = pcall(require, "nvim-navic")
              return ok and navic.is_available()
            end,
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            function() return require("nvim-navic").get_location() end,
            cond = function()
              local ok, navic = pcall(require, "nvim-navic")
              return ok and navic.is_available()
            end,
          },
        },
      },
    },
    config = function(_, opts)
      local lualine = require("lualine")
      -- "minimal" drops everything but mode/filename/diagnostics -- the
      -- statusline_style toggle in the Konfigurationsmaske.
      local minimal_opts = vim.tbl_deep_extend("force", opts, {
        sections = {
          lualine_a = { "mode" },
          lualine_b = {},
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "diagnostics" },
          lualine_y = {},
          lualine_z = {},
        },
      })

      local function apply(style)
        lualine.setup(style == "minimal" and minimal_opts or opts)
      end

      local state = require("settings").state
      apply(state.get().statusline_style)
      state.register("statusline_style", apply)
    end,
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        separator_style = "thin",
        show_close_icon = false,
        show_buffer_close_icons = true,
        always_show_bufferline = false,
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Honor the persisted visibility toggle from the settings UI.
      local state = require("settings").state
      local function apply_visibility(visible)
        vim.opt.showtabline = visible and 2 or 0
      end
      apply_visibility(state.get().bufferline_visible)
      state.register("bufferline_visible", apply_visibility)
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
    },
    config = function(_, opts)
      local ibl = require("ibl")
      local state = require("settings").state
      local function apply(enabled)
        ibl.setup(vim.tbl_deep_extend("force", opts, { enabled = enabled }))
      end
      apply(state.get().indent_guides)
      state.register("indent_guides", apply)
    end,
  },

  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      notification = { window = { winblend = 0 } },
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      -- Centered command-line / search popup instead of the bottom bar.
      cmdline = { view = "cmdline_popup" },
      -- The command_palette preset below pins cmdline_popup to a fixed
      -- `row = 3` (near the top) and cmdline_popupmenu to a fixed `row = 6`.
      -- Overriding both here wins, since noice merges user opts last via
      -- vim.tbl_deep_extend("force", ...). A plain string for
      -- cmdline_popupmenu's position (not a table) fully replaces the
      -- preset's fixed offset and restores noice's own "auto" behavior,
      -- which anchors the popup menu to the cmdline's actual screen row.
      views = {
        cmdline_popup = { position = { row = "50%", col = "50%" } },
        cmdline_popupmenu = { position = "auto" },
      },
      messages = { view = "mini" },
      popupmenu = { backend = "cmp" }, -- overridden by blink.cmp integration, see lua/plugins/completion.lua
      -- fidget.nvim owns LSP-progress display; avoid a duplicate indicator.
      lsp = {
        progress = { enabled = false },
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = {
        bottom_search = false,
        command_palette = true, -- centers cmdline + popupmenu together
        long_message_to_split = true,
      },
    },
  },

  {
    "rcarriga/nvim-notify",
    opts = { timeout = 3000, render = "wrapped-compact" },
  },

  -- Highlights other occurrences of the word under the cursor (via LSP
  -- references where available, a Treesitter/regex fallback otherwise) --
  -- the same "read/write reference" highlighting every IDE does automatically.
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 200,
      -- No LSP/no meaningful "word" in these -- would just add visual noise.
      filetypes_denylist = { "neo-tree", "snacks_dashboard", "lazy", "mason", "TelescopePrompt" },
    },
    config = function(_, opts) require("illuminate").configure(opts) end,
  },

  -- Right-hand scrollbar with diagnostic/git-change/search/cursor markers --
  -- VS Code's "overview ruler" equivalent. gitsigns (lua/plugins/git.lua)
  -- and nvim-lint/LSP diagnostics already produce the data this reads; no
  -- extra wiring needed on their end.
  {
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    opts = {
      winblend = 0,
      handlers = {
        cursor = { enable = true },
        search = { enable = true },
        diagnostic = { enable = true },
        gitsigns = { enable = true },
        marks = { enable = false }, -- redundant with the sign column already showing these
      },
    },
  },

  -- snacks.nvim is a multi-module utility plugin, already pulled in as a bare
  -- dependency by lua/plugins/claude.lua (claudecode.nvim's terminal
  -- provider). lazy.nvim merges every spec fragment for the same plugin name
  -- into one, so this is simply the rest of that shared plugin's config, not
  -- a second install. `lazy = false` here is what makes the merged result
  -- load at startup instead of only once a ClaudeCode* command first runs --
  -- both smooth scrolling and the dashboard need to be there from frame one.
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      scroll = { enabled = true },

      -- Start screen. Replaces alpha-nvim (removed): same header/keys idea,
      -- plus two live-data panes on the right so it isn't just a static menu.
      -- The block-letter header is deliberately unicode/wide -- an
      -- intentional exception to the house 120-char line-length style (see
      -- ~/.claude/CLAUDE.md), scoped to this decorative string literal only.
      -- "AXIOMATA" is this config's own name (renamed from "AXIOM" on
      -- 2026-08-25), not a plugin or upstream project -- rendered in the
      -- "ANSI Shadow" figlet font to match the previous plain "NEOVIM"
      -- header.
      dashboard = {
        enabled = true,
        preset = {
          header = [[
 █████╗ ██╗  ██╗██╗ ██████╗ ███╗   ███╗ █████╗ ████████╗ █████╗
██╔══██╗╚██╗██╔╝██║██╔═══██╗████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗
███████║ ╚███╔╝ ██║██║   ██║██╔████╔██║███████║   ██║   ███████║
██╔══██║ ██╔██╗ ██║██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══██║
██║  ██║██╔╝ ██╗██║╚██████╔╝██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝]],
          -- Mirrors the old alpha-nvim buttons, plus "Find projects" (this
          -- repo's own curated picker, lua/util/projects.lua -- kept instead
          -- of snacks' built-in git-root-scanning "projects" section so
          -- there's only one project-discovery mechanism, not two).
          keys = {
            { icon = " ", key = "n", desc = "New file", action = ":enew | startinsert" },
            { icon = " ", key = "f", desc = "Find file", action = ":Telescope find_files" },
            {
              icon = "  ",
              key = "p",
              desc = "Find projects",
              action = function() require("util.projects").picker() end,
            },
            { icon = " ", key = "g", desc = "Live grep", action = ":Telescope live_grep" },
            { icon = " ", key = "r", desc = "Recent files", action = ":Telescope oldfiles" },
            {
              icon = " ",
              key = "s",
              desc = "Restore session",
              action = function() require("persistence").load() end,
            },
            {
              icon = " ",
              key = "c",
              desc = "Settings",
              action = function() require("settings").open() end,
            },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          -- Rotates once per calendar day (day-of-year modulo the tip
          -- count) rather than via math.random -- deterministic, so it
          -- doesn't depend on whether Neovim's Lua state happens to be
          -- seeded, and still varies day to day.
          {
            align = "center",
            padding = 1,
            text = {
              { DASHBOARD_TIPS[(tonumber(os.date("%j")) % #DASHBOARD_TIPS) + 1], hl = "NonText" },
            },
          },
          { section = "startup" }, -- footer: "N plugins loaded in Mms" (lazy.nvim stats)
          -- Second pane: live data instead of more static buttons.
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function() return Snacks.git.get_root() ~= nil end,
            cmd = "git status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60, -- cache for 5 min; re-running `git status` on every dashboard render is wasteful
            indent = 3,
          },
          -- Open TODO/FIXME/HACK comments in the project, same keywords
          -- todo-comments.nvim (lua/plugins/editor.lua) highlights inline --
          -- a quick "what's left" glance without opening Trouble (<leader>xt).
          {
            pane = 2,
            icon = " ",
            title = "TODOs",
            section = "terminal",
            enabled = function() return Snacks.git.get_root() ~= nil and vim.fn.executable("rg") == 1 end,
            cmd = "rg --no-heading --line-number --color=never -e 'TODO|FIXME|HACK' -g '!node_modules' -m 5",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
        },
      },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      icons = { mappings = true },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)

      local groups = require("config.keymaps").groups
      local mappings = {}
      for prefix, group in pairs(groups) do
        table.insert(mappings, { "<leader>" .. prefix, group = group.icon .. " " .. group.name })
      end
      wk.add(mappings)
    end,
  },
}
