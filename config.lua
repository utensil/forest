-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match("(.*/)")
package.path = package.path .. ';' .. current_dir .. '?.lua'

require "init"

lvim.builtin.treesitter.rainbow.enable = true
lvim.colorscheme = 'base16-railscasts'

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
        -- have to remove this for the auto-completion to have a non-nil `forester_current_config`
        -- event = "VeryLazy",
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
            { "nvim-treesitter/nvim-treesitter" },
            { "nvim-lua/plenary.nvim" }
        },
        -- -- maybe could be even lazier with these, but not working
        -- ft = "tree",
        -- ft = "forester",
        config = function()
            -- can't run this because it treesitter might not be initialized
            -- vim.cmd.TSInstall "toml"

            -- this ensures that the treesitter is initialized, and toml is installed
            local configs = require("nvim-treesitter.configs")
            configs.setup {
                ensure_installed = { "toml" },
            }

            -- this ensures forester is initialized, makeing `forester` tree-sitter available
            require("forester").setup()

            -- can't run this explicitly, because next launch of nvim will ask for reinstallation
            -- vim.cmd.TSInstall "forester"

            -- installs the forester tree-sitter, so the syntax highlighting is available
            configs.setup {
                ensure_installed = { "toml", "forester" }
            }
        end,
    },
    {
        "github/copilot.vim",
    }
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

vim.schedule(function()
    -- vim.cmd.TSInstall "forester"

    -- Lua
    -- vim.cmd.colorscheme "railscasts"
end)

-- require("forester").setup()

local foresterCompletionSource = require("forester.completion")

local cmp = require("cmp")

cmp.register_source("forester", foresterCompletionSource)
cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })
