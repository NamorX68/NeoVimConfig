return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
        vim.o.timeout = true
        vim.o.timeoutlen = 200
    end,
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    config = function ()
        local wk = require("which-key")
        wk.register({
            ["<leader>f"] = {
                name = "+File",
                p = { "<cmd>Telescope find_files<cr>", "Project Files" },
                g = { "<cmd>Telescope live_grep<cr>", "Files Grep" },
                f = { "<cmd>lua vim.lsp.buf.format()<cr>", "File Format"},
                r = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" },
                b = {":Neotree buffers reveal float<CR>", "File Buffers"},

            },

            ["<leader>s"] = {
                name = "Search",
                h = { "<cmd>Telescope help_tags<cr>", "Find Help" },
                H = { "<cmd>Telescope highlights<cr>", "Find highlight groups" },
                M = { "<cmd>Telescope man_pages<cr>", "Man Pages" },
                R = { "<cmd>Telescope registers<cr>", "Registers" },
                k = { "<cmd>Telescope keymaps<cr>", "Keymaps" },
                C = { "<cmd>Telescope commands<cr>", "Commands" },
                l = { "<cmd>Telescope resume<cr>", "Resume last search" },
            },

            ["<leader>c"] = {
                name = "Code",
                a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
                d = { "<cmd>lua vim.lsp.buf.definition()<cr>", "Goto Definition" },
                D = { "<cmd>lua vim.lsp.buf.declaration()<cr>", "Goto Declaration" },
                i = { "<cmd>lua vim.lsp.buf.implementation()<cr>", "Goto Implementation" },
                n = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
                r = { "<cmd>Telescope lsp_references<cr>", "References"},
                s = { "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols" },
                S = { "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>","Workspace Symbols" },
                h = { "<cmd>lua vim.lsp.buf.hover()<cr>", "Hover" },
            },

            ["<leader>d"] = {
                name = "Debug",
                t = { "<cmd>lua require'dap'.toggle_breakpoint()<cr>", "Toggle Breakpoint" },
                b = { "<cmd>lua require'dap'.step_back()<cr>", "Step Back" },
                c = { "<cmd>lua require'dap'.continue()<cr>", "Continue" },
                C = { "<cmd>lua require'dap'.run_to_cursor()<cr>", "Run To Cursor" },
                d = { "<cmd>lua require'dap'.disconnect()<cr>", "Disconnect" },
                g = { "<cmd>lua require'dap'.session()<cr>", "Get Session" },
                i = { "<cmd>lua require'dap'.step_into()<cr>", "Step Into" },
                o = { "<cmd>lua require'dap'.step_over()<cr>", "Step Over" },
                u = { "<cmd>lua require'dap'.step_out()<cr>", "Step Out" },
                p = { "<cmd>lua require'dap'.pause()<cr>", "Pause" },
                r = { "<cmd>lua require'dap'.repl.toggle()<cr>", "Toggle Repl" },
                s = { "<cmd>lua require'dap'.continue()<cr>", "Start" },
                q = { "<cmd>lua require'dap'.close()<cr>", "Quit" },
                U = { "<cmd>lua require'dapui'.toggle({reset = true})<cr>", "Toggle UI" },
            },

            ["<leader>g"] = {
                name = "Git",
                j = { "<cmd>lua require 'gitsigns'.next_hunk({navigation_message = false})<cr>", "Next Hunk" },
                k = { "<cmd>lua require 'gitsigns'.prev_hunk({navigation_message = false})<cr>", "Prev Hunk" },
                l = { "<cmd>lua require 'gitsigns'.blame_line()<cr>", "Blame" },
                t = { "<cmd>lua require 'gitsigns'.toggle_current_line_blame()<cr>", "Toggle Line Blame"},
                p = { "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", "Preview Hunk" },
                r = { "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", "Reset Hunk" },
                R = { "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", "Reset Buffer" },
                s = { "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", "Stage Hunk" },
                u = { "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", "Undo Stage Hunk" },
                o = { "<cmd>Telescope git_status<cr>", "Open changed file" },
                b = { "<cmd>Telescope git_branches<cr>", "Checkout branch" },
                c = { "<cmd>Telescope git_commits<cr>", "Checkout commit" },
                C = { "<cmd>Telescope git_bcommits<cr>", "Checkout commit(for current file)" },
                d = { "<cmd>Gitsigns diffthis HEAD<cr>", "Git Diff" },
            },

            ["<leader>t"] = {
                name = "Terminal",
                r = { "<cmd>vertical belowright split | vertical resize -20 | terminal<CR>", "Right" },
                b = { "<cmd>horizontal  botright split | resize -7 | terminal<CR>", "Bottom" },
            },

            ["<leader>A"] = {
                name = "ChatGPT",
                c = { "<cmd>ChatGPT<CR>", "ChatGPT" },
                e = { "<cmd>ChatGPTEditWithInstruction<CR>", "Edit with instruction", mode = { "n", "v" } },
                g = { "<cmd>ChatGPTRun grammar_correction<CR>", "Grammar Correction", mode = { "n", "v" } },
                t = { "<cmd>ChatGPTRun translate<CR>", "Translate", mode = { "n", "v" } },
                k = { "<cmd>ChatGPTRun keywords<CR>", "Keywords", mode = { "n", "v" } },
                d = { "<cmd>ChatGPTRun docstring<CR>", "Docstring", mode = { "n", "v" } },
                a = { "<cmd>ChatGPTRun add_tests<CR>", "Add Tests", mode = { "n", "v" } },
                o = { "<cmd>ChatGPTRun optimize_code<CR>", "Optimize Code", mode = { "n", "v" } },
                s = { "<cmd>ChatGPTRun summarize<CR>", "Summarize", mode = { "n", "v" } },
                f = { "<cmd>ChatGPTRun fix_bugs<CR>", "Fix Bugs", mode = { "n", "v" } },
                x = { "<cmd>ChatGPTRun explain_code<CR>", "Explain Code", mode = { "n", "v" } },
                r = { "<cmd>ChatGPTRun roxygen_edit<CR>", "Roxygen Edit", mode = { "n", "v" } },
                l = { "<cmd>ChatGPTRun code_readability_analysis<CR>", "Code Readability Analysis", mode = { "n", "v" } },
            },

        })
    end
}
