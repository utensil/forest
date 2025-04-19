return {
  "AstroNvim/astrocommunity",
    -- example of importing a plugin
    -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
    -- see docs at https://astronvim.github.io/astrocommunity/
    -- { import = "astrocommunity.colorscheme.catppuccin" },
    { import = "astrocommunity.pack.rust" },
    { import = "astrocommunity.pack.python" },
    { import = "astrocommunity.pack.just" },
    { import = "astrocommunity.pack.html-css"},
    { import = "astrocommunity.pack.markdown" },
    { import = "astrocommunity.pack.lean" },
    -- https://astronvim.github.io/astrocommunity/#copilot-vim-cmp
    { import = "astrocommunity.completion.copilot-vim-cmp" },
    { import = "astrocommunity.diagnostics.trouble-nvim" },
    { import = "astrocommunity.motion.mini-ai" },
    { import = "astrocommunity.utility.noice-nvim" }
}
