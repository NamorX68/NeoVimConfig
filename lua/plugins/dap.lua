-- Debugging (DAP). Breakpoints/step/watch keymaps live in the <leader>d
-- group in lua/config/keymaps.lua; this file only wires up adapters and
-- per-language launch configurations.
--
-- Rust is intentionally NOT configured here: rustaceanvim (see
-- lua/plugins/lsp.lua) registers its own codelldb-backed
-- dap.configurations.rust the first time a *.rs buffer loads, generated
-- from the actual Cargo targets -- duplicating that by hand here would
-- both be redundant and drift out of sync with the real build.

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      -- Explicit dependency (not just implied by lua/plugins/lsp.lua):
      -- config() below calls require("mason-registry") unconditionally, so
      -- mason.nvim must be guaranteed on runtimepath even if a DAP keymap
      -- is the very first thing pressed in a session, before any buffer
      -- has triggered nvim-lspconfig's own BufReadPre/BufNewFile loading.
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local mason_registry = require("mason-registry")

      require("mason-nvim-dap").setup({
        ensure_installed = { "python", "codelldb", "js" },
        automatic_installation = true,
        handlers = {}, -- keep each adapter's default handler (registers dap.adapters[...])
      })

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Python: nvim-dap-python wires debugpy for us. Two DIFFERENT
      -- interpreters are involved and must not be conflated:
      --   1. The first argument below is the interpreter that RUNS the
      --      debugpy adapter process itself -- always Mason's own debugpy
      --      install, regardless of which project is open.
      --   2. `opts.pythonPath` is the interpreter that runs the DEBUGGEE
      --      (the user's code) -- this should follow the active project
      --      venv (lua/plugins/venv.lua). Passed as a function: nvim-dap
      --      re-evaluates function-valued config fields on every debug
      --      session start (see dap.lua's prepare_config/eval_option), not
      --      just once at setup() time, so this stays correct across venv
      --      switches without restarting Neovim. Returning nil when no venv
      --      is selected makes dap-python fall back to its own default
      --      (get_python_path()), matching the previous behavior exactly.
      require("dap-python").setup(mason_registry.get_package("debugpy"):get_install_path() .. "/venv/bin/python", {
        pythonPath = function()
          local ok, venv_selector = pcall(require, "venv-selector")
          local python = ok and venv_selector.python()
          return (python and python ~= "") and python or nil
        end,
      })

      -- C/C++: no build-system integration exists to auto-generate a
      -- config (unlike Rust via rustaceanvim), so this simply prompts for
      -- the compiled binary to launch.
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = mason_registry.get_package("codelldb"):get_install_path() .. "/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }
      dap.configurations.cpp = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp

      -- JavaScript/TypeScript via js-debug-adapter (pwa-node).
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            mason_registry.get_package("js-debug-adapter"):get_install_path() .. "/js-debug/src/dapDebugServer.js",
            "${port}",
          },
        },
      }
      for _, language in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo" })
    end,
  },
}
