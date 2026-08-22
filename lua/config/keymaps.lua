-- Central keymap specification -- the single source of truth for every
-- <leader>, plain, and Cmd (<D-...>) keybinding in this configuration. This
-- table is consumed three times:
--   1. M.apply() below -> plain vim.keymap.set loop, called once from init.lua
--   2. lua/plugins/palette.lua -> which-key.add() (group labels/icons from M.groups)
--   3. lua/plugins/palette.lua -> legendary.nvim (auto-registered via which-key)
--
-- rhs values that need a plugin (`function() require("telescope.builtin")...`)
-- use a DEFERRED require inside a closure on purpose: requiring a lazy.nvim
-- plugin module still triggers lazy-loading correctly no matter where the
-- require happens, so these keymaps can be set eagerly at startup without
-- forcing every plugin to load eagerly too.

local M = {}

-- Group prefix -> { name, icon } consumed by which-key.add() for the
-- top-level <leader> popup, and mirrored into legendary's item groups.
M.groups = {
  a = { name = "AI", icon = "" },
  o = { name = "Opencode", icon = "" },
  f = { name = "Find", icon = "" },
  g = { name = "Git", icon = "" },
  D = { name = "Docker", icon = "" },
  d = { name = "Debug", icon = "" },
  T = { name = "Test", icon = "" },
  l = { name = "LSP / Code", icon = "" },
  x = { name = "Diagnostics", icon = "" },
  e = { name = "Explorer", icon = "" },
  c = { name = "Config", icon = "" },
  t = { name = "Terminal", icon = "" },
  b = { name = "Buffers", icon = "" },
  w = { name = "Window", icon = "" },
}

-- Plain, non-leader "muscle memory" keymaps: window/buffer navigation,
-- line moving, indenting, saving.
M.base = {
  { "<C-h>", "<C-w>h", desc = "Go to left window" },
  { "<C-j>", "<C-w>j", desc = "Go to lower window" },
  { "<C-k>", "<C-w>k", desc = "Go to upper window" },
  { "<C-l>", "<C-w>l", desc = "Go to right window" },

  { "<S-h>", "<cmd>bprevious<cr>", desc = "Previous buffer" },
  { "<S-l>", "<cmd>bnext<cr>", desc = "Next buffer" },

  { "<A-j>", "<cmd>m .+1<cr>==", desc = "Move line down" },
  { "<A-k>", "<cmd>m .-2<cr>==", desc = "Move line up" },
  { "<A-j>", ":m '>+1<cr>gv=gv", mode = "v", desc = "Move selection down" },
  { "<A-k>", ":m '<-2<cr>gv=gv", mode = "v", desc = "Move selection up" },

  -- Same window-nav keys as above, but for terminal-mode buffers (Claude
  -- Code's split, toggleterm floats, ...): terminal buffers start in
  -- terminal-insert mode and swallow <C-w>-style commands otherwise, so
  -- without these there is no keyboard-only way out of e.g. the Claude
  -- window back into a code buffer. <C-\><C-n> exits terminal mode first,
  -- then the normal <C-w>{h,j,k,l} runs.
  { "<C-h>", "<C-\\><C-n><C-w>h", mode = "t", desc = "Go to left window" },
  { "<C-j>", "<C-\\><C-n><C-w>j", mode = "t", desc = "Go to lower window" },
  { "<C-k>", "<C-\\><C-n><C-w>k", mode = "t", desc = "Go to upper window" },
  { "<C-l>", "<C-\\><C-n><C-w>l", mode = "t", desc = "Go to right window" },

  { "<", "<gv", mode = "v", desc = "Indent left, keep selection" },
  { ">", ">gv", mode = "v", desc = "Indent right, keep selection" },

  { "<C-d>", "<C-d>zz", desc = "Half-page down, centered" },
  { "<C-u>", "<C-u>zz", desc = "Half-page up, centered" },

  { "<esc>", "<cmd>nohlsearch<cr>", desc = "Clear search highlight" },
  { "<C-s>", "<cmd>write<cr>", desc = "Save file" },
  { "<C-s>", "<esc><cmd>write<cr>", mode = "i", desc = "Save file" },

  -- Go to definition/declaration -- the one pair core 0.11+ deliberately
  -- left unmapped (see the "LSP / Code" comment below: grr/gra/gri/grt/gO
  -- ARE core defaults, this isn't). Overrides Vim's own `gd` ("go to local
  -- declaration", a buffer-local text search) with the LSP version, which is
  -- what every other editor's "gd" muscle memory expects. `<C-o>`/`<C-i>`
  -- (built into Vim, no mapping needed) jump back/forward through the
  -- resulting jumplist -- the "and back again" half of go-to-definition.
  { "gd", vim.lsp.buf.definition, desc = "Go to definition" },
  { "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },

  -- Overrides core 0.11+'s own `grr` (vim.lsp.buf.references(), raw
  -- quickfix list) with Trouble's lsp_references view -- grouped by file,
  -- with a preview pane, same UI family as <leader>xx/<leader>xd below
  -- instead of a second, differently-styled list type for "where is this
  -- used".
  { "grr", function() require("trouble").toggle("lsp_references") end, desc = "References (Trouble)" },
}

-- Leader-prefixed keymaps, grouped by concern. Each entry: { lhs, rhs, desc, mode? }.
M.leader = {
  -- AI (Claude Code). track_selection stays at claudecode.nvim's default
  -- (true, see lua/plugins/claude.lua) -- Claude already sees the current
  -- buffer and any selection in real time, no keymap needed for that part;
  -- these cover the remaining explicit actions (force-add a file, resolve a
  -- proposed diff). Adding files from neo-tree instead lives in neo-tree's
  -- own window.mappings (lua/plugins/neotree.lua), not here -- same "as"
  -- key, but scoped to the tree buffer's filetype, which this table has no
  -- mechanism to express.
  { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
  { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },
  { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
  { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer to Claude context" },
  { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
  { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Reject Claude diff" },

  -- Opencode (local/self-hosted LLM -- lua/plugins/opencode.lua). Separate
  -- group from "a" (Claude) rather than merged in: different CLI, different
  -- plugin, worth keeping discoverable as its own thing rather than
  -- implying they're interchangeable modes of one tool.
  { "<leader>ot", function() require("util.opencode").toggle() end, desc = "Toggle Opencode" },
  {
    "<leader>oa",
    function() require("opencode").ask("@this: ") end,
    mode = { "n", "x" },
    desc = "Ask Opencode about this",
  },
  -- Prompt library (explain/fix/review/test/optimize/document/implement/
  -- diagnose) and available commands/servers all live behind this one
  -- picker -- see opencode.nvim's own README rather than duplicating each
  -- prompt as a separate keymap here.
  { "<leader>os", function() require("opencode").select() end, mode = { "n", "x" }, desc = "Opencode prompts/commands" },

  -- Find (Telescope)
  { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
  { "<leader>fp", function() require("util.projects").picker() end, desc = "Find projects" },
  { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Live grep" },
  { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find buffers" },
  { "<leader>fr", function() require("telescope.builtin").oldfiles() end, desc = "Recent files" },
  { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
  { "<leader>fk", function() require("telescope.builtin").keymaps() end, desc = "Keymaps" },
  { "<leader>fw", function() require("telescope.builtin").grep_string() end, desc = "Grep word under cursor" },
  { "<leader>fd", function() require("telescope.builtin").diagnostics() end, desc = "Diagnostics" },
  -- Search & replace (grug-far.nvim) -- the missing REPLACE half of fg's
  -- live_grep (which only finds). Normal mode opens blank; visual mode
  -- prefills the search with whatever's selected, same split as Claude's as.
  { "<leader>fs", function() require("grug-far").open() end, desc = "Search & replace" },
  {
    "<leader>fs",
    function() require("grug-far").with_visual_selection() end,
    mode = "v",
    desc = "Search & replace selection",
  },

  -- Git
  { "<leader>gg", function() require("util.terminal").lazygit() end, desc = "LazyGit" },
  { "<leader>gs", function() require("gitsigns").stage_hunk() end, desc = "Stage hunk" },
  { "<leader>gr", function() require("gitsigns").reset_hunk() end, desc = "Reset hunk" },
  { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview hunk" },
  { "<leader>gb", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle line blame" },
  { "<leader>gd", function() require("gitsigns").diffthis() end, desc = "Diff this" },
  { "<leader>gl", function() require("telescope.builtin").git_commits() end, desc = "Commits" },
  { "<leader>gB", function() require("telescope.builtin").git_branches() end, desc = "Branches" },
  -- git-conflict.nvim (lua/plugins/git.lua) itself only gives buffer-local
  -- co/ct/cb/c0/[x/]x once a conflicted file is open; this is the one
  -- addition, listing every conflicted file/hunk across the repo at once.
  { "<leader>gL", "<cmd>GitConflictListQf<cr>", desc = "List conflicts (repo-wide)" },

  -- Docker (capital D -- lowercase d is the Debug group)
  { "<leader>Dd", function() require("util.terminal").lazydocker() end, desc = "LazyDocker" },

  -- Debug (DAP)
  { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
  {
    "<leader>dB",
    function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,
    desc = "Conditional breakpoint",
  },
  { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
  { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
  { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
  { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
  { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
  { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
  { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
  { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },

  -- Test (neotest, lua/plugins/testing.lua) -- Python/pytest only for now,
  -- see that file's header comment for why Rust stays on rustaceanvim's own
  -- runner instead of a second neotest adapter.
  { "<leader>Tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
  { "<leader>Tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run current file" },
  {
    "<leader>Td",
    function() require("neotest").run.run({ strategy = "dap" }) end,
    desc = "Debug nearest test",
  },
  { "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop test" },
  { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
  { "<leader>To", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },

  -- LSP / Code (supplementary to core 0.11+ gr*/gO/gs defaults, left
  -- untouched; gd/gD live in M.base above instead, since they're plain,
  -- non-leader mappings like the defaults they extend)
  { "<leader>la", vim.lsp.buf.code_action, desc = "Code action" },
  { "<leader>lr", vim.lsp.buf.rename, desc = "Rename symbol" },
  -- Docstring scaffold under the cursor's function/class (neogen, Google
  -- style for Python -- lua/plugins/editor.lua).
  { "<leader>ld", function() require("neogen").generate() end, desc = "Generate docstring" },
  { "<leader>lf", function() require("conform").format({ lsp_fallback = true }) end, desc = "Format buffer" },
  {
    "<leader>li",
    function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
    desc = "Toggle inlay hints",
  },
  -- Distinct from li above: inlay hints are LSP type/parameter annotations,
  -- this CYCLES how error/warning messages render (see lua/plugins/diagnostics.lua
  -- for what each style means). Mirrors the "Diagnostics style" row's cycle
  -- behavior in the settings UI (lua/settings/ui.lua) -- both drive the same
  -- applier registered by lua/plugins/diagnostics.lua, so either entry point
  -- stays in sync and persists.
  {
    "<leader>lI",
    function()
      local settings = require("settings")
      local styles = { "virtual_text", "current_line", "virtual_lines", "inline" }
      local current = settings.state.get().diagnostics_style
      local index = 1
      for i, style in ipairs(styles) do
        if style == current then
          index = i
          break
        end
      end
      local next_style = styles[(index % #styles) + 1]
      settings.state.set("diagnostics_style", next_style)
      vim.notify("Diagnostics style: " .. next_style, vim.log.levels.INFO)
    end,
    desc = "Cycle diagnostics style",
  },
  { "<leader>ls", function() require("telescope.builtin").lsp_document_symbols() end, desc = "Document symbols" },
  {
    "<leader>lS",
    function() require("telescope.builtin").lsp_dynamic_workspace_symbols() end,
    desc = "Workspace symbols",
  },
  { "<leader>lx", "<cmd>LspRestart<cr>", desc = "Restart LSP client" },
  { "<leader>lv", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },

  -- Diagnostics / Trouble
  { "<leader>xx", function() require("trouble").toggle("diagnostics") end, desc = "Diagnostics (workspace)" },
  {
    "<leader>xd",
    function() require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } }) end,
    desc = "Diagnostics (buffer)",
  },
  { "<leader>xq", function() require("trouble").toggle("qflist") end, desc = "Quickfix list" },
  { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "TODO list" },

  -- Explorer (neo-tree)
  { "<leader>ee", "<cmd>Neotree toggle<cr>", desc = "Toggle explorer" },
  { "<leader>ef", "<cmd>Neotree reveal<cr>", desc = "Reveal current file" },
  { "<leader>eg", "<cmd>Neotree float git_status<cr>", desc = "Git status view" },

  -- Config / Settings
  { "<leader>cs", function() require("settings").open() end, desc = "Open settings UI" },
  { "<leader>cp", "<cmd>Lazy<cr>", desc = "Plugin manager (Lazy)" },
  { "<leader>cm", "<cmd>Mason<cr>", desc = "Tool installer (Mason)" },
  { "<leader>cl", "<cmd>checkhealth<cr>", desc = "Check health" },
  -- Reopens the start screen (lua/plugins/ui.lua). It also reopens itself
  -- automatically once the last real buffer closes, so this is for the
  -- "I'm mid-session and just want to get back to it" case.
  { "<leader>cd", "<cmd>Dashboard<cr>", desc = "Open start screen" },

  -- Terminal
  { "<leader>tt", function() require("util.terminal").float() end, desc = "Toggle floating terminal" },
  { "<leader>th", function() require("util.terminal").horizontal() end, desc = "Horizontal terminal" },
  { "<leader>tv", function() require("util.terminal").vertical() end, desc = "Vertical terminal" },

  -- Buffers
  { "<leader>bb", function() require("bufferline").pick() end, desc = "Pick buffer" },
  -- Vim's own "alternate buffer" register (`:h CTRL-^`) -- jumps straight
  -- back to whichever buffer you were in immediately before this one, no
  -- picker needed. With exactly two buffers open this is a perfect toggle;
  -- <C-^> already does the exact same thing with zero config, this just
  -- gives it a which-key-discoverable name under the same group as bb/bd/bo.
  { "<leader>bl", "<cmd>b#<cr>", desc = "Last buffer (toggle)" },
  { "<leader>bd", function() require("mini.bufremove").delete(0, false) end, desc = "Delete buffer" },
  {
    "<leader>bo",
    function()
      local current = vim.api.nvim_get_current_buf()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current and vim.bo[buf].buflisted then
          require("mini.bufremove").delete(buf, false)
        end
      end
    end,
    desc = "Close other buffers",
  },

  -- Window
  { "<leader>ws", "<cmd>split<cr>", desc = "Split horizontal" },
  { "<leader>wv", "<cmd>vsplit<cr>", desc = "Split vertical" },
  { "<leader>wd", "<cmd>close<cr>", desc = "Close window" },
  { "<leader>wo", "<cmd>only<cr>", desc = "Close other windows" },
  -- Capital W, not a leaf under the "w" prefix above: a leaf there would add
  -- a timeoutlen-long delay to ws/wv/wd/wo while Neovim waits to see if more
  -- keys follow. See lua/util/windowmode.lua for why this mode exists.
  {
    "<leader>W",
    function() require("util.windowmode").toggle() end,
    desc = "Toggle window mode (no modifier holding)",
  },

  -- Command palette (VS Code Ctrl+Shift+P equivalent)
  { "<leader><leader>", function() require("legendary").find() end, desc = "Command palette" },
}

-- macOS Cmd (<D-...>) shortcuts. Only letters Ghostty (the terminal this
-- config is used in) does NOT bind by default are used here, so these work
-- with zero Ghostty configuration -- verified via `ghostty +list-keybinds
-- --default`. The one exception is <D-w>, which needs one Ghostty keybind
-- freed (see ~/Library/Application Support/com.mitchellh.ghostty/config);
-- everything else below already reaches Neovim unmodified.
-- Each entry mirrors an existing <leader>... binding above -- Cmd is an
-- additive, muscle-memory shortcut layer, not a replacement for the leader
-- keymaps or their which-key/legendary discoverability.
M.mac = {
  { "<D-s>", "<cmd>write<cr>", desc = "Save file" },
  { "<D-s>", "<esc><cmd>write<cr>", mode = "i", desc = "Save file" },
  -- Closes the BUFFER (Mac "close document" idiom), deliberately distinct
  -- from <leader>wd (closes the split/window).
  { "<D-w>", function() require("mini.bufremove").delete(0, false) end, desc = "Close buffer" },
  { "<D-p>", function() require("telescope.builtin").find_files() end, desc = "Find files" },
  { "<D-o>", function() require("util.projects").picker() end, desc = "Find projects" },
  { "<D-b>", function() require("bufferline").pick() end, desc = "Pick buffer" },
  { "<D-l>", vim.lsp.buf.code_action, desc = "Code action" },
  {
    "<D-i>",
    function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
    desc = "Toggle inlay hints",
  },
  { "<D-r>", function() require("dap").continue() end, desc = "Continue / start debugging" },
  { "<D-m>", "<cmd>Mason<cr>", desc = "Tool installer (Mason)" },
  { "<D-h>", function() require("telescope.builtin").help_tags() end, desc = "Help tags" },
  { "<D-x>", function() require("trouble").toggle("diagnostics") end, desc = "Diagnostics (workspace)" },
}

--- Apply every keymap in M.base, M.leader and M.mac via vim.keymap.set.
function M.apply()
  for _, maps in ipairs({ M.base, M.leader, M.mac }) do
    for _, map in ipairs(maps) do
      vim.keymap.set(map.mode or "n", map[1], map[2], { desc = map.desc, silent = true })
    end
  end
end

return M
