local plugins = {
    -- {
    --   "lukelex/railscasts.nvim",
    --   dependencies = { "rktjmp/lush.nvim" }
    -- },
    {
        "RRethy/base16-nvim",
        lazy = false,
        -- config = function()
        --     vim.cmd('colorscheme base16-railscasts')
        -- end
    },
    {
        "j-hui/fidget.nvim",
        opts = {
            -- options
        },
    },
    { "lewis6991/satellite.nvim" },
    {
        "kentookura/forester.nvim",
        -- before = { "nvim-cmp" },
        branch = "36-installation-and-initialization",
        -- tried removing this for the auto-completion to have a non-nil `forester_current_config`
        event = "VeryLazy",
        dependencies = {
            { "nvim-telescope/telescope.nvim" },
            { "nvim-treesitter/nvim-treesitter" },
            { "nvim-lua/plenary.nvim" },
            { "hrsh7th/nvim-cmp" },
        },
        -- -- maybe could be even lazier with these, but not working, because `forester` filetype is not registered yet
        -- ft = "tree",
        -- ft = "forester",
        config = function()
            -- can't run this because it treesitter might not be initialized
            -- vim.cmd.TSInstall "toml"

            -- this ensures that the treesitter is initialized, and toml is installed
            local configs = require "nvim-treesitter.configs"
            configs.setup {
                ensure_installed = { "toml" },
                sync_install = true,
            }

            -- this ensures forester is initialized, makeing `forester` tree-sitter available
            require("forester").setup()

            -- can't run this explicitly, because next launch of nvim will ask for reinstallation
            -- vim.cmd.TSInstall "forester"

            -- installs the forester tree-sitter, so the syntax highlighting is available
            configs.setup {
                ensure_installed = { "toml", "forester" },
                sync_install = false,
            }
            -- local foresterCompletionSource = require "forester.completion"
            -- local cmp = require "cmp"
            -- cmp.register_source("forester", foresterCompletionSource)
            -- cmp.setup.filetype("forester", { sources = { { name = "forester", dup = 0 } } })
            -- cmp.setup()
        end,
    },
    -- https://github.com/mrcjkb/rustaceanvim/discussions/94#discussioncomment-7813716 not working:
    -- error: lazy.nvim/lua/lazy/core/loader.lua:373: attempt to call field 'setup' (a table value)
    -- {
    --     "mrcjkb/rustaceanvim",
    --     version = "^3", -- Recommended
    --     ft = { "rust" },
    -- },
    -- {
    --     "neovim/nvim-lspconfig",
    --     opts = {
    --         setup = {
    --             rust_analyzer = function()
    --                 return true
    --             end,
    --         },
    --     },
    -- },
    {
        "mrcjkb/rustaceanvim",
        version = "^5", -- Recommended
        lazy = false, -- This plugin is already lazy
        -- ft = { "rust" },
        -- config = function()
        --   vim.g.rustaceanvim = {
        --     server = {
        --       on_attach = require("lvim.lsp").common_on_attach
        --     },
        --   }
        -- end,
    },
    {
        "github/copilot.vim",
        event = "VeryLazy",
    },
    -- {
    --     "zbirenbaum/copilot.lua",
    -- },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        event = "VeryLazy",
        branch = "canary",
        dependencies = {
            -- { "zbirenbaum/copilot.lua" },
            { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
            { "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        build = "make tiktoken", -- Only on MacOS or Linux
        opts = {
            -- debug = true, -- Enable debugging
            -- See Configuration section for rest
            window = {
                layout = "float",
                relative = "cursor",
                width = 1,
                height = 0.4,
                row = 1,
            },
        },
        -- adapted from https://github.com/jellydn/lazy-nvim-ide/blob/main/lua/plugins/extras/copilot-chat-v2.lua
        -- config = function(_, opts)
        --     local chat = require "CopilotChat"
        --     local select = require "CopilotChat.select"
        --     -- Use unnamed register for the selection
        --     opts.selection = select.unnamed

        --     -- Override the git prompts message
        --     opts.prompts.Commit = {
        --         prompt = "Write commit message for the change with commitizen convention",
        --         selection = select.gitdiff,
        --     }
        --     opts.prompts.CommitStaged = {
        --         prompt = "Write commit message for the change with commitizen convention",
        --         selection = function(source)
        --             return select.gitdiff(source, true)
        --         end,
        --     }

        --     chat.setup(opts)
        --     -- Setup the CMP integration
        --     require("CopilotChat.integrations.cmp").setup()

        --     vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
        --         chat.ask(args.args, { selection = select.visual })
        --     end, { nargs = "*", range = true })

        --     -- Inline chat with Copilot
        --     vim.api.nvim_create_user_command("CopilotChatInline", function(args)
        --         chat.ask(args.args, {
        --             selection = select.visual,
        --             window = {
        --                 layout = "float",
        --                 relative = "cursor",
        --                 width = 1,
        --                 height = 0.4,
        --                 row = 1,
        --             },
        --         })
        --     end, { nargs = "*", range = true })

        --     -- Restore CopilotChatBuffer
        --     vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
        --         chat.ask(args.args, { selection = select.buffer })
        --     end, { nargs = "*", range = true })

        --     -- Custom buffer for CopilotChat
        --     vim.api.nvim_create_autocmd("BufEnter", {
        --         pattern = "copilot-*",
        --         callback = function()
        --             vim.opt_local.relativenumber = true
        --             vim.opt_local.number = true

        --             -- Get current filetype and set it to markdown if the current filetype is copilot-chat
        --             local ft = vim.bo.filetype
        --             if ft == "copilot-chat" then
        --                 vim.bo.filetype = "markdown"
        --             end
        --         end,
        --     })
        -- end,
        keys = {
            -- Code related commands
            { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
            { "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
            { "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
            { "<leader>aR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
            { "<leader>an", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
            -- -- Chat with Copilot in visual mode
            -- {
            --     "<leader>av",
            --     "<cmd>CopilotChatVisual<cr>",
            --     mode = "x",
            --     desc = "CopilotChat - Open in vertical split",
            -- },
            -- {
            --     "<leader>ax",
            --     "<cmd>CopilotChatInline<cr>",
            --     mode = "x",
            --     desc = "CopilotChat - Inline chat",
            -- },
            -- Custom input for CopilotChat
            {
                "<leader>ai",
                function()
                    local input = vim.fn.input "Ask Copilot: "
                    if input ~= "" then
                        vim.cmd("CopilotChat " .. input)
                    end
                end,
                desc = "CopilotChat - Ask input",
            },
            -- Generate commit message based on the git diff
            {
                "<leader>am",
                "<cmd>CopilotChatCommit<cr>",
                desc = "CopilotChat - Generate commit message for all changes",
            },
            {
                "<leader>aM",
                "<cmd>CopilotChatCommitStaged<cr>",
                desc = "CopilotChat - Generate commit message for staged changes",
            },
            -- -- Quick chat with Copilot
            -- {
            --     "<leader>aq",
            --     function()
            --         local input = vim.fn.input "Quick Chat: "
            --         if input ~= "" then
            --             vim.cmd("CopilotChatBuffer " .. input)
            --         end
            --     end,
            --     desc = "CopilotChat - Quick chat",
            -- },
            -- Debug
            { "<leader>ad", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
            -- Fix the issue with diagnostic
            { "<leader>af", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - Fix Diagnostic" },
            -- Clear buffer and chat history
            { "<leader>al", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Clear buffer and chat history" },
            -- Toggle Copilot Chat Vsplit
            { "<leader>av", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
            -- Also toggle, easier to type
            { "<leader>aa", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
            -- Copilot Chat Models
            { "<leader>a?", "<cmd>CopilotChatModels<cr>", desc = "CopilotChat - Select Models" },
        },
    },
    {
        "Julian/lean.nvim",
        event = { "BufReadPre *.lean", "BufNewFile *.lean" },

        dependencies = {
            "neovim/nvim-lspconfig",
            "nvim-lua/plenary.nvim",
            -- you also will likely want nvim-cmp or some completion engine
        },

        -- see details below for full configuration options
        opts = {
            lsp = {},
            mappings = true,
        },
    },
    {
        "sindrets/diffview.nvim",
        event = "BufRead",
    },
    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        -- keys = {
        --     { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
        -- }
    },
    {
        "topaxi/gh-actions.nvim",
        keys = {
            { "<leader>gh", "<cmd>GhActions<cr>", desc = "Open Github Actions" },
            {
                "<leader>gq",
                function()
                    require("gh-actions").close()
                end,
                desc = "Close Github Actions",
            },
        },
        -- optional, you can also install and use `yq` instead.
        -- build = 'make',
        ---@type GhActionsConfig
        opts = {
            icons = {
                workflow_dispatch = "⚡️",
                conclusion = {
                    success = "✅",
                    failure = "❌",
                    startup_failure = "❗",
                    cancelled = "⊘",
                    skipped = "◌",
                },
                status = {
                    unknown = "?",
                    pending = "○",
                    queued = "○",
                    requested = "○",
                    waiting = "○",
                    in_progress = "●",
                },
            },
        },
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
    },
    { "wakatime/vim-wakatime", lazy = false },
    -- {
    --     "pwntester/octo.nvim",
    --     dependencies = {
    --         "nvim-lua/plenary.nvim",
    --         "nvim-telescope/telescope.nvim",
    --         "nvim-tree/nvim-web-devicons",
    --     },
    --     config = function()
    --         require("octo").setup()
    --     end,
    -- },
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    -- {
    --     "yetone/avante.nvim",
    --     event = "VeryLazy",
    --     lazy = false,
    --     version = false, -- set this if you want to always pull the latest change
    --     opts = {
    --         provider = "copilot",
    --         ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
    --     },
    --     -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    --     build = "make",
    --     -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    --     dependencies = {
    --         "nvim-treesitter/nvim-treesitter",
    --         "stevearc/dressing.nvim",
    --         "nvim-lua/plenary.nvim",
    --         "MunifTanjim/nui.nvim",
    --         --- The below dependencies are optional,
    --         "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --         "zbirenbaum/copilot.lua", -- for providers='copilot'
    --         {
    --             -- support for image pasting
    --             "HakonHarnes/img-clip.nvim",
    --             event = "VeryLazy",
    --             opts = {
    --                 -- recommended settings
    --                 default = {
    --                     embed_image_as_base64 = false,
    --                     prompt_for_file_name = false,
    --                     drag_and_drop = {
    --                         insert_mode = true,
    --                     },
    --                     -- required for Windows users
    --                     use_absolute_path = true,
    --                 },
    --             },
    --         },
    --         {
    --             -- Make sure to set this up properly if you have lazy=true
    --             "MeanderingProgrammer/render-markdown.nvim",
    --             opts = {
    --                 file_types = { "markdown", "Avante" },
    --             },
    --             ft = { "markdown", "Avante" },
    --         },
    --     },
    -- },
    {
        "nvim-pack/nvim-spectre",
        event = "BufRead",
        config = function()
            require("spectre").setup {
                use_trouble_qf = true,
                default = {
                    replace = {
                        cmd = "sd",
                    },
                },
            }
        end,
        keys = {
            { "<leader>ss", "<cmd>lua require('spectre').toggle()<cr>", desc = "Toggle Spectre" },
            {
                "<leader>sw",
                "<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
                desc = "Spectre (word)",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            {
                "SmiteshP/nvim-navbuddy",
                dependencies = {
                    "SmiteshP/nvim-navic",
                    "MunifTanjim/nui.nvim",
                },
                opts = { lsp = { auto_attach = true } },
            },
        },
        -- your lsp config or other stuff
    },
    -- play also https://www.vim-hero.com/lessons/basic-movement
    -- { "ThePrimeagen/vim-be-good" }
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        ft = "markdown",
        config = function()
            vim.g.mkdp_auto_start = 1
        end,
    },
    {
        "zbirenbaum/copilot-cmp",
        after = { "copilot.lua", "nvim-cmp" },
        config = function()
            require("copilot_cmp").setup()
        end,
    },
    -- {
    --     "Zeioth/hot-reload.nvim",
    --     dependencies = "nvim-lua/plenary.nvim",
    --     event = "BufEnter",
    --     opts = {}
    -- }
}

return plugins
