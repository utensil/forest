return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = { "hrsh7th/cmp-emoji", "kentookura/forester.nvim" },
        ---@param opts cmp.ConfigSchema
        opts = function(_, opts)
            table.insert(opts.sources, { name = "emoji" })
        end,
    },
}
