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
    -- https://essais.co/better-folding-in-neovim/
    foldenable = false,
    foldlevel = 0,
    -- foldmethod = "indent",
    foldmethod = "expr",
    foldexpr = "nvim_treesitter#foldexpr()",
}

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46_cache/"

-- set local leader, won't work for LazyVim, as it has mapped "  "  to find files
if vim.g.maplocalleader == nil or vim.g.maplocalleader == "\\" then
    vim.g.maplocalleader = "  "
end

-- https://github.com/LunarVim/Neovim-from-scratch/blob/master/lua/user/keymaps.lua

local opts = { noremap = true, silent = true }

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
keymap("n", "U", "<C-r>", opts)

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

-- doesn't work
-- keymap("v", "/", "gc", opts)

-- vim.schedule(function()
--     dofile(vim.g.base46_cache .. "defaults")
--     dofile(vim.g.base46_cache .. "statusline")
-- end)

-- https://stackoverflow.com/a/70760302/200764
vim.diagnostic.config {
    virtual_text = false,
}

-- Show line diagnostics automatically in hover window
-- vim.o.updatetime = 250
-- vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]

-- https://samuellawrentz.com/hacks/neovim/disable-annoying-eslint-lsp-server-and-hide-virtual-text/
-- Disable ESLint LSP server and hide virtual text in Neovim
-- Add this to your init.lua or init.vim file
local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>lx", function()
    isLspDiagnosticsVisible = not isLspDiagnosticsVisible
    vim.diagnostic.config {
        virtual_text = isLspDiagnosticsVisible,
        underline = isLspDiagnosticsVisible,
    }
end)
