-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

lvim.plugins = {
    -- {
    --   "lukelex/railscasts.nvim",
    --   dependencies = { "rktjmp/lush.nvim" }
    -- },
    { "RRethy/base16-nvim" }
}

vim.schedule(function()
    -- Lua
    -- vim.cmd.colorscheme "railscasts"
    vim.cmd('colorscheme base16-railscasts')
end)
