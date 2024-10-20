-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match("(.*/)")
package.path = package.path .. ';' .. current_dir .. '?.lua'

require "init"

-- to prevent colision with rusteceanvim: not working
-- https://github.com/mrcjkb/rustaceanvim/discussions/174#discussioncomment-8193827
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })

-- https://github.com/mrcjkb/rustaceanvim/discussions/94#discussioncomment-7813716: not working
require("mason-lspconfig").setup_handlers {
    ["rust_analyzer"] = function() end,
}

lvim.plugins = {
    -- {
    --   "lukelex/railscasts.nvim",
    --   dependencies = { "rktjmp/lush.nvim" }
    -- },
    {
        "RRethy/base16-nvim",
        lazy = false,
        -- config = function()
        --     vim.cmd('colorscheme base16-railscasts')
        -- end
    },
    {
        "kentookura/forester.nvim",
        -- tried removing this for the auto-completion to have a non-nil `forester_current_config`
        event = "VeryLazy",
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
            { "nvim-treesitter/nvim-treesitter" },
            { "nvim-lua/plenary.nvim" },
            { "hrsh7th/nvim-cmp" }
        },
        -- -- maybe could be even lazier with these, but not working, because `forester` filetype is not registered yet
        -- ft = "tree",
        -- ft = "forester",
        config = function()
            -- can't run this because it treesitter might not be initialized
            -- vim.cmd.TSInstall "toml"

            -- this ensures that the treesitter is initialized, and toml is installed
            local configs = require("nvim-treesitter.configs")
            configs.setup {
                ensure_installed = { "toml" },
                sync_install = true,
            }

            -- this ensures forester is initialized, makeing `forester` tree-sitter available
            require("forester").setup()

            -- can't run this explicitly, because next launch of nvim will ask for reinstallation
            -- vim.cmd.TSInstall "forester"

            -- installs the forester tree-sitter, so the syntax highlighting is available
            configs.setup {
                ensure_installed = { "toml", "forester" },
                sync_install = false,
            }

            -- local foresterCompletionSource = require("forester.completion")

            -- local cmp = require("cmp")

            -- cmp.register_source("forester", foresterCompletionSource)
            -- cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })

            -- cmp.setup()
        end,
    },
    -- https://github.com/mrcjkb/rustaceanvim/discussions/94#discussioncomment-7813716 not working
    -- {
    --     "neovim/nvim-lspconfig",
    --     opts = {
    --       setup = {
    --         rust_analyzer = function()
    --           return true
    --         end,
    --       },
    --     },
    -- },
    {
        'mrcjkb/rustaceanvim',
        version = '^5', -- Recommended
        lazy = false, -- This plugin is already lazy
        -- ft = { "rust" },
        -- config = function()
        --   vim.g.rustaceanvim = {
        --     server = {
        --       on_attach = require("lvim.lsp").common_on_attach
        --     },
        --   }
        -- end,
    },
    {
        "github/copilot.vim",
        event = "VeryLazy",
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        event = "VeryLazy",
        branch = "canary",
        dependencies = {
          { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
          { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        build = "make tiktoken", -- Only on MacOS or Linux
        opts = {
          debug = true, -- Enable debugging
          -- See Configuration section for rest
        },
        -- See Commands section for default commands if you want to lazy load on them
      },
    -- play also https://www.vim-hero.com/lessons/basic-movement
    { "ThePrimeagen/vim-be-good" }
    -- {
    --     "iamcco/markdown-preview.nvim",
    --     build = "cd app && npm install",
    --     ft = "markdown",
    --     config = function()
    --       vim.g.mkdp_auto_start = 1
    --     end,
    -- }
    -- {
    --     "Zeioth/hot-reload.nvim",
    --     dependencies = "nvim-lua/plenary.nvim",
    --     event = "BufEnter",
    --     opts = {}
    -- }
}

lvim.colorscheme = 'base16-railscasts'
lvim.builtin.treesitter.rainbow.enable = true
