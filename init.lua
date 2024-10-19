-- Adapted from https://github.com/LunarVim/Neovim-from-scratch/blob/master/lua/user/options.lua
local options = {
    backup = false,
    fileencoding = "utf-8",
    number = true,
    relativenumber = true,
    smartindent = true,
    tabstop = 4,
    wrap = true,
    linebreak = true,
}

for k, v in pairs(options) do
    vim.opt[k] = v
end

-- https://github.com/LunarVim/Neovim-from-scratch/blob/master/lua/user/keymaps.lua

local keymap = vim.keymap.set

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
keymap("n", "-", ":resize -2<CR>", opts)
keymap("n", "=", ":resize +2<CR>", opts)
keymap("n", "<C-->", ":vertical resize -2<CR>", opts)
keymap("n", "<C-=>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- use U for redo :))
keymap('n', 'U', '<C-r>', opts)

-- terminal
-- keymap("t", "<C-h>", "<cmd>wincmd h<CR>", opts)
-- keymap("t", "<C-j>", "<cmd>wincmd j<CR>", opts)
-- keymap("t", "<C-k>", "<cmd>wincmd k<CR>", opts)
-- keymap("t", "<C-l>", "<cmd>wincmd l<CR>", opts)

-- Insert --
-- Press jk fast to exit insert mode
keymap("i", "jk", "<ESC>", opts)
keymap("i", "kj", "<ESC>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv^", opts)
keymap("v", ">", ">gv^", opts)

keymap("v", "/", "gc", opts)
