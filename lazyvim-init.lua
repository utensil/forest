local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match "(.*/)"
package.path = package.path .. ";" .. current_dir .. "?.lua"

dofile(current_dir .. "init.lua")
dofile(current_dir .. "nvim-init.lua")

vim.schedule(function()
    vim.cmd "colorscheme base16-railscasts"
end)

local cmp = require "cmp"
local foresterCompletionSource = require "forester.completion"

cmp.register_source("forester", foresterCompletionSource)
-- cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })
