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

      -- Work around a known incompatibility between nvim-treesitter's frozen
      -- `master` branch (unmaintained; the plugin's original maintainer has
      -- archived the project) and Neovim 0.12+: for the fenced-code-block
      -- info-string capture, `match[capture_id]` can come back as an empty
      -- table instead of a single node. query_predicates.lua passes that
      -- straight into `get_node_text()` / `get_range()`, which then calls
      -- `:range()` on nil, crashing the markdown highlighter on every fenced
      -- code block that names a language (```sh, ```lua, ...). Re-register
      -- the three affected directives with a defensive unwrap. This survives
      -- `:TSUpdate` since it runs from our own config, not a vendored file.
      -- Upstream: https://github.com/neovim/neovim/issues/39032
      --           https://github.com/nvim-treesitter/nvim-treesitter/issues/8618
      local ts_query = require("vim.treesitter.query")
      local directive_opts = { force = true, all = false }

      -- Mirrors the private table in nvim-treesitter/query_predicates.lua.
      local info_string_aliases = { ex = "elixir", pl = "perl", sh = "bash", uxn = "uxntal", ts = "typescript" }

      ---@param match (TSNode|nil|TSNode[])[]
      local function safe_node(match, capture_id)
        local node = match[capture_id]
        if type(node) == "table" then
          node = node[1]
        end
        return node
      end

      ts_query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local node = safe_node(match, pred[2])
        if not node then
          return
        end
        local alias = vim.treesitter.get_node_text(node, bufnr):lower()
        local ft_match = vim.filetype.match({ filename = "a." .. alias })
        metadata["injection.language"] = ft_match or info_string_aliases[alias] or alias
      end, directive_opts)

      local html_script_type_languages = {
        ["importmap"] = "json",
        ["module"] = "javascript",
        ["application/ecmascript"] = "javascript",
        ["text/ecmascript"] = "javascript",
      }
      ts_query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
        local node = safe_node(match, pred[2])
        if not node then
          return
        end
        local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
        local configured = html_script_type_languages[type_attr_value]
        if configured then
          metadata["injection.language"] = configured
        else
          local parts = vim.split(type_attr_value, "/", {})
          metadata["injection.language"] = parts[#parts]
        end
      end, directive_opts)

      ts_query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
        local id = pred[2]
        local node = safe_node(match, id)
        if not node then
          return
        end
        local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
        metadata[id] = metadata[id] or {}
        metadata[id].text = string.lower(text)
      end, directive_opts)
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
