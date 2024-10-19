-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match("(.*/)")
package.path = package.path .. ';' .. current_dir .. '?.lua'

require "init"

lvim.plugins = {
    -- {
    --   "lukelex/railscasts.nvim",
    --   dependencies = { "rktjmp/lush.nvim" }
    -- },
    { "RRethy/base16-nvim" },
    {
        "kentookura/forester.nvim",
        -- event = "VeryLazy",
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
            { "nvim-treesitter/nvim-treesitter" },
            { "nvim-lua/plenary.nvim" },
        },
    }
    -- {
    --     "Zeioth/hot-reload.nvim",
    --     dependencies = "nvim-lua/plenary.nvim",
    --     event = "BufEnter",
    --     opts = {}
    -- }
}

vim.schedule(function()
    -- Lua
    -- vim.cmd.colorscheme "railscasts"
    vim.cmd('colorscheme base16-railscasts')

    require("forester").setup()

    local foresterCompletionSource = require("forester.completion")

    require("cmp").register_source("forester", foresterCompletionSource)
    require("cmp").setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })

end)
