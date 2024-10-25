-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match "(.*/)"
package.path = package.path .. ";" .. current_dir .. "?.lua"

require "nvim-init"

-- to prevent colision with rusteceanvim
-- https://github.com/mrcjkb/rustaceanvim/discussions/174#discussioncomment-8193827
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "rust_analyzer" })

-- In order for the above to work, one must excute `:LvimCacheReset` manually'
-- or uncomment the following
vim.schedule(function()
    vim.cmd "LvimCacheReset"
end)

-- -- https://github.com/mrcjkb/rustaceanvim/discussions/94#discussioncomment-7813716: not working
-- require("mason-lspconfig").setup_handlers {
--     ["rust_analyzer"] = function() end,
-- }

lvim.plugins = require "uts-plugins"

lvim.colorscheme = "base16-railscasts"
lvim.builtin.treesitter.rainbow.enable = true
-- lvim.builtin.cmp.active = false

-- lvim.builtin.cmp
--

-- table.insert(lvim.builtin.cmp.sources, { name = "forester" })

-- lvim.builtin.cmp.on_config_done = function(cmp)
--     local foresterCompletionSource = require "forester.completion"
--     -- local cmp = require "cmp"
--     cmp.register_source("forester", foresterCompletionSource)
--     cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })
--     cmp.setup()
-- end
