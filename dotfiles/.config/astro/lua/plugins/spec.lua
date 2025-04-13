return {
    {
        "RRethy/base16-nvim",
        lazy = false,
        config = function()
            vim.cmd "colorscheme base16-railscasts"
        end,
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
    -- {
    --     "kentookura/forester.nvim",
    --     -- "utensil/forester.nvim",
    --     -- branch = "main",
    --     -- dir = "/Users/utensil/projects/forester.nvim",
    --     -- before = { "nvim-cmp" },
    --     -- branch = "36-installation-and-initialization",
    --     -- tried removing this for the auto-completion to have a non-nil `forester_current_config`
    --     event = "VeryLazy",
    --     dependencies = {
    --         { "nvim-telescope/telescope.nvim" },
    --         { "nvim-treesitter/nvim-treesitter" },
    --         { "nvim-lua/plenary.nvim" },
    --         { "hrsh7th/nvim-cmp" },
    --     },
    --     -- -- maybe could be even lazier with these, but not working, because `forester` filetype is not registered yet
    --     -- ft = "tree",
    --     -- ft = "forester",
    --     config = function()
    --         -- can't run this because it treesitter might not be initialized
    --         -- vim.cmd.TSInstall "toml"

    --         -- this ensures that the treesitter is initialized, and toml is installed
    --         local configs = require "nvim-treesitter.configs"
    --         configs.setup {
    --             ensure_installed = { "toml" },
    --             sync_install = true,
    --         }

    --         -- this ensures forester is initialized, makeing `forester` tree-sitter available
    --         require("forester").setup()

    --         -- can't run this explicitly, because next launch of nvim will ask for reinstallation
    --         -- vim.cmd.TSInstall "forester"

    --         -- installs the forester tree-sitter, so the syntax highlighting is available
    --         configs.setup {
    --             ensure_installed = { "toml", "forester" },
    --             sync_install = false,
    --         }

    --         -- local foresterCompletionSource = require "forester.completion"
    --         -- local cmp = require "cmp"
    --         -- cmp.register_source("forester", foresterCompletionSource)
    --         -- cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })
    --         -- cmp.setup()
    --     end,
    --     keys = {
    --         { "<localleader>n", "<cmd>Forester new<cr>", desc = "Forester - New" },
    --         { "<localleader>b", "<cmd>Forester browse<cr>", desc = "Forester - Browse" },
    --         { "<localleader>l", "<cmd>Forester link_new<cr>", desc = "Forester - Link New" },
    --         { "<localleader>t", "<cmd>Forester transclude_new<cr>", desc = "Forester - Transclude New" },
    --         {
    --             "<localleader>c",
    --             function()
    --                 local cmd = "just new"
    --                 local prefix = vim.fn.input "Enter prefix: "
    --                 if not prefix:match "^[a-z]+$" or #prefix > 10 then
    --                     print "Error: Prefix must be no more than 10 lowercase a-z characters."
    --                     return
    --                 end
    --                 if prefix ~= "" then
    --                     cmd = cmd .. " " .. prefix
    --                 else
    --                     cmd = cmd .. " uts"
    --                 end
    --                 local file = io.popen(cmd):read "*a"
    --                 vim.cmd("e " .. file)
    --             end,
    --             desc = "Forester - New from Command",
    --         },
    --     },
    -- },
}
