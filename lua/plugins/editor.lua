-- Treesitter and general editor tooling: syntax/indent, auto-pairs, jump
-- motions, TODO highlighting, a pretty diagnostics/quickfix list, session
-- persistence, inline color previews, layout-preserving buffer removal,
-- project-wide search & replace, docstring generation, rainbow-colored
-- nested brackets, and cursor/window motion animations.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- One parser per in-scope language (Python, Rust, CSS, HTML,
      -- JS/TS, C/C++) plus the config-editing/docs languages.
      ensure_installed = {
        "python",
        "rust",
        "css",
        "scss",
        "html",
        "javascript",
        "typescript",
        "tsx",
        "c",
        "cpp",
        "lua",
        "vim",
        "vimdoc",
        "bash",
        "markdown",
        "markdown_inline",
        "json",
        "yaml",
        "toml",
        "dockerfile",
        "regex",
        "diff",
        "gitcommit",
        "gitignore",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  {
    -- Correct comment strings inside embedded filetypes (e.g. <script> in
    -- .html, CSS-in-JS). Native gc/gcc (Neovim 0.10+) handles the rest, so
    -- Comment.nvim is deliberately not added -- it would be redundant.
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = { enable_autocmd = false },
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
    },
  },

  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = { options = { "buffers", "curdir", "tabpages", "winsize" } },
  },

  {
    -- Maintained fork; the original norcalli/nvim-colorizer.lua is
    -- unmaintained.
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = { filetypes = { "css", "scss", "html", "javascript", "typescript", "lua", "conf" } },
  },

  {
    "echasnovski/mini.nvim",
    version = false,
    event = "VeryLazy",
    config = function()
      -- Only bufremove and animate are used (layout-preserving buffer
      -- delete, backs <leader>bd / <leader>bo in lua/config/keymaps.lua).
      require("mini.bufremove").setup()

      -- Cursor-jump trail, window resize, and float open/close animations --
      -- the "Wämm" visual-polish pass. `scroll` is deliberately disabled:
      -- snacks.nvim (lua/plugins/ui.lua, `scroll = { enabled = true }`)
      -- already smooth-scrolls, and running both would double-animate every
      -- scroll.
      require("mini.animate").setup({
        scroll = { enable = false },
      })
    end,
  },

  -- Rainbow-colored nested brackets/parens -- HiPhish/rainbow-delimiters.nvim
  -- is the maintained successor to the archived nvim-ts-rainbow(2); it reads
  -- the same Treesitter parsers already installed above, no extra parser
  -- config needed. `main` points lazy.nvim's `opts` handling at the actual
  -- setup module (the plugin's own require path is
  -- "rainbow-delimiters.setup", not "rainbow-delimiters").
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "rainbow-delimiters.setup",
    opts = {
      highlight = {
        "RainbowDelimiterRed",
        "RainbowDelimiterYellow",
        "RainbowDelimiterBlue",
        "RainbowDelimiterOrange",
        "RainbowDelimiterGreen",
        "RainbowDelimiterViolet",
        "RainbowDelimiterCyan",
      },
    },
  },

  -- Project-wide search & replace with a live preview buffer before
  -- anything is written to disk -- Telescope's live_grep (lua/plugins/
  -- telescope.lua) only FINDS across files, this is the missing REPLACE
  -- half. Keymaps in lua/config/keymaps.lua's Find group (<leader>fs).
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
  },

  -- Docstring scaffolding (<leader>ld in lua/config/keymaps.lua). Python
  -- generates Google-style docstrings, matching the format mandated in
  -- ~/.claude/python.md. snippet_engine = "nvim" uses core :h vim.snippet
  -- (Neovim 0.10+) for the jumpable placeholders -- no LuaSnip dependency,
  -- consistent with blink.cmp already being the only snippet engine here
  -- (see lua/plugins/completion.lua).
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    cmd = "Neogen",
    opts = {
      snippet_engine = "nvim",
      languages = {
        python = { template = { annotation_convention = "google_docstrings" } },
      },
    },
  },
}
