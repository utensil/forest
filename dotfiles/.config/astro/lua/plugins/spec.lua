return {
    {
        "RRethy/base16-nvim",
        lazy = false,
        -- config = function()
        --     vim.cmd "colorscheme base16-railscasts"
        -- end,
    },
    {
        "tribela/transparent.nvim",
        event = "VimEnter",
        config = true,
    },
    {
        "oxtna/vshow.nvim",
        config = function()
            require("vshow").setup {
                all = {
                    { character = "eol", symbol = "↲" },
                    { character = "tab", symbol = "→•" },
                    { character = "space", symbol = "·" },
                    { character = "multispace", symbol = "··" },
                    { character = "lead", symbol = "·" },
                    { character = "trail", symbol = "-" },
                    { character = "extends", symbol = "" },
                    { character = "precedes", symbol = "" },
                    { character = "conceal", symbol = "" },
                    { character = "nbsp", symbol = "+" },
                },
                -- char = {},
                -- line = {},
                -- block = {},
            }
        end,
    },
    { "wakatime/vim-wakatime", lazy = false },
    {
        "nvchad/showkeys",
        cmd = "ShowkeysToggle",
        opts = {
            timeout = 1,
            maxkeys = 7,
            show_count = true,
            excluded_modes = { "i" },
            position = "top-right",
            winopts = {
                focusable = false,
                relative = "editor",
                style = "minimal",
                border = "rounded",
                height = 1,
                row = 1,
                col = 0,
            },
        },
        keys = {
            { "<leader>kk", "<cmd>ShowkeysToggle<cr>", desc = "Show Keys" },
        },
    },
    {
        "folke/persistence.nvim",
        event = "BufReadPre", -- this will only start session saving when an actual file was opened
        opts = {
            -- add any custom options here
        },
        keys = {
            {
                "<leader>rs",
                function()
                    require("persistence").load()
                end,
                "Load the session for the current working directory",
            },
            {
                "<leader>rS",
                function()
                    require("persistence").select()
                end,
                "Select a session to load",
            },
        },
    },
    {
        "hedyhli/outline.nvim",
        lazy = true,
        cmd = { "Outline", "OutlineOpen" },
        keys = { -- Example mapping to toggle outline
            { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
        },
        opts = {
            symbol_folding = {
                autofold_depth = 1,
                auto_unfold = {
                    hovered = true,
                },
            },
            auto_jump = true,
            outline_window = {
                auto_jump = true,
            },
            -- preview_window = {
            --     auto_preview = true,
            -- },
        },
    },
}

