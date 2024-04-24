return {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    config = function()
        require("rust-tools").setup()
    end,
}
