local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match "(.*/)"
package.path = package.path .. ";" .. current_dir .. "?.lua"

-- override local leader before loading LazyVim, doesn't work, has to be in lua/lazyvim/config/options.lua
-- so, LazyVim will keep the default local leader `\`
-- set local leader for NVChad
if vim.g.maplocalleader == nil then
    vim.g.maplocalleader = "  "
end

-- loading LazyVim
dofile(current_dir .. "init.lua")

-- override other settings after loading LazyVim
dofile(current_dir .. "nvim-init.lua")

-- vim.schedule(function()
--     vim.cmd "colorscheme base16-railscasts"
-- end)

-- local cmp = require "cmp"
-- local foresterCompletionSource = require "forester.completion"
--
-- cmp.register_source("forester", foresterCompletionSource)
-- cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })
