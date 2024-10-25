local current_file = debug.getinfo(1, "S").source:sub(2)
local current_dir = current_file:match "(.*/)"
package.path = package.path .. ";" .. current_dir .. "?.lua"

dofile(current_dir .. "nvim-init.lua")
dofile(current_dir .. "init.lua")

vim.schedule(function()
    vim.cmd "colorscheme base16-railscasts"
end)
