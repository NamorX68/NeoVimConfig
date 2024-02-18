return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "leoluz/nvim-dap-go",
        "rcarriga/nvim-dap-ui",
        "tpope/vim-fugitive",
        "mfussenegger/nvim-dap-python",
    },
    config = function()
        require("dapui").setup()
        require("dap-go").setup()
        require("dap-python").setup("~/.local/share/nvim/mason/packages/debugpy/venv/bin/python")

        local dap, dapui = require("dap"), require("dapui")

        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end

        vim.keymap.set("n", "<Leader>db", ":DapToggleBreakpoint<CR>")
        vim.keymap.set("n", "<F5>", ":DapContinue<CR>")
        vim.keymap.set("n", "<F6>", ":DapStepOver<CR>")
        vim.keymap.set("n", "<F7>", ":DapStepInto<CR>")
        vim.keymap.set("n", "<F8>", ":DapStepOut<CR>")
        vim.keymap.set("n", "<Leader>dx", ":DapTerminate<CR>")
    end,
}
