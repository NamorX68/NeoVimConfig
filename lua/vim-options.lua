vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.g.mapleader = " "

-- Navigate vim panes better
vim.keymap.set("n", "<c-k>", ":wincmd k<CR>")
vim.keymap.set("n", "<c-j>", ":wincmd j<CR>")
vim.keymap.set("n", "<c-h>", ":wincmd h<CR>")
vim.keymap.set("n", "<c-l>", ":wincmd l<CR>")

vim.keymap.set("n", "<leader>h", ':nohlsearch<CR>')

vim.keymap.set("n", "<CS-j>", ":m .+1<CR>")
vim.keymap.set("n", "<CS-k>", ":m .-2<CR>")
vim.keymap.set("v", "<CS-j>", ":m '>+1<CR>gv")
vim.keymap.set("v", "<CS-k>", ":m '<-2<CR>gv")

--vim.keymap.set('n', '<leader>tr', ':vertical belowright split | :vertical resize -20 | :terminal<CR>')
vim.keymap.set('n', '<leader>tb', ':horizontal  botright split | :resize -7 | :terminal<CR>')

vim.wo.number = true
vim.wo.relativenumber = true

vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.backup = false

vim.g.transparent_enabled = true

