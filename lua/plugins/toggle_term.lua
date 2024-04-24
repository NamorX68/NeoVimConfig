return {
    'akinsho/toggleterm.nvim',
    config = function ()
        require('toggleterm').setup({
            size = 80,
            open_mapping = [[<c-#>]],
            direction = "float",
            hide_numbers = true,
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            float_opts = {
                border = "curved",
                winblend = 0,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                }
            }

        })
    end
}
