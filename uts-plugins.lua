local plugins = {
    -- {
    --   "lukelex/railscasts.nvim",
    --   dependencies = { "rktjmp/lush.nvim" }
    -- },
    {
        "RRethy/base16-nvim",
        lazy = false,
        -- config = function()
        --     vim.cmd "colorscheme base16-railscasts"
        -- end,
    },
    -- {
    --     "folke/tokyonight.nvim",
    --     lazy = true,
    --     opts = { style = "moon" },
    -- },
    { "echasnovski/mini.ai", version = false },
    -- {
    --     "echasnovski/mini.nvim",
    --     version = false,
    --     config = function()
    --         require("mini.ai").setup {}
    --     end,
    -- },
    -- { "saghen/blink.compat",
    --     opts = {
    --         impersonate_nvim_cmp = true,
    --     }
    -- },
    -- { "hrsh7th/cmp-emoji" },
    -- {
    --     "allaman/emoji.nvim",
    --     version = "1.0.0", -- optionally pin to a tag
    --     ft = "markdown", -- adjust to your needs
    --     dependencies = {
    --         -- util for handling paths
    --         "nvim-lua/plenary.nvim",
    --         -- optional for nvim-cmp integration
    --         -- "hrsh7th/nvim-cmp",
    --         -- optional for telescope integration
    --         "nvim-telescope/telescope.nvim",
    --     },
    --     opts = {
    --         -- default is false
    --         enable_cmp_integration = false,
    --         -- optional if your plugin installation directory
    --         -- is not vim.fn.stdpath("data") .. "/lazy/
    --         -- plugin_path = vim.fn.expand "$HOME/plugins/",
    --     },
    --     config = function(_, opts)
    --         require("emoji").setup(opts)
    --         -- optional for telescope integration
    --         local ts = require("telescope").load_extension "emoji"
    --         vim.keymap.set("n", "<leader>se", ts.emoji, { desc = "[S]earch [E]moji" })
    --     end,
    -- },
    -- {
    --     "xiyaowong/telescope-emoji.nvim",
    --     dependencies = {
    --         "nvim-telescope/telescope.nvim",
    --     },
    --     config = function()
    --         require("telescope").load_extension "emoji"
    --     end,
    --     keys = {
    --         { "<leader>se", "<cmd>Telescope emoji<cr>", desc = "Search Emoji" },
    --     },
    -- },
    {
        "nvim-telescope/telescope-symbols.nvim",
        keys = {
            { "<leader>se", "<cmd>Telescope symbols<cr>", desc = "Search Symbols: emoji, latex" },
        },
    },
    {
        "saghen/blink.cmp",
        lazy = false, -- lazy loading handled internally
        -- optional: provides snippets for the snippet source
        dependencies = "rafamadriz/friendly-snippets",
        -- use a release tag to download pre-built binaries
        version = "v0.*",

        -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
        -- build = 'cargo build --release',
        -- If you use nix, you can build from source using latest nightly rust with:
        -- build = 'nix run .#build-plugin',
        opts = {
            -- 'default' for mappings similar to built-in completion
            -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
            -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
            -- see the "default configuration" section below for full documentation on how to define
            -- your own keymap.
            keymap = {
                ["<C-q>"] = { "show", "hide" },
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
                ["<Right>"] = { "accept", "fallback" },
                ["<Left>"] = { "hide" },
            },

            highlight = {
                -- sets the fallback highlight groups to nvim-cmp's highlight groups
                -- useful for when your theme doesn't support blink.cmp
                -- will be removed in a future release, assuming themes add support
                use_nvim_cmp_as_default = true,
            },

            -- set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- adjusts spacing to ensure icons are aligned
            nerd_font_variant = "mono",

            -- experimental auto-brackets support
            accept = { auto_brackets = { enabled = true } },

            -- experimental signature help support
            -- trigger = { signature_help = { enabled = true }, show_in_snippet = false },

            sources = {
                completion = {
                    enabled_providers = { "lsp", "path", "snippets", "buffer" }, -- , "emoji" }, -- , 'buffer' },
                },
            },
            providers = {
                snippets = {
                    enabled = function(ctx)
                        return ctx ~= nil
                            and ctx.trigger.kind == vim.lsp.protocol.CompletionTriggerKind.TriggerCharacter
                    end,
                },
            },
            windows = {
                autocomplete = {
                    auto_show = false,
                    selection = "manual",
                    draw = "reversed",
                    -- winblend = vim.o.pumblend,
                },
                documentation = {
                    auto_show = false,
                },
                ghost_text = {
                    enabled = false,
                },
            },
            -- providers = {
            --     -- create provider
            --     emoji = {
            --         name = "emoji", -- IMPORTANT: use the same name as you would for nvim-cmp
            --         module = "blink.compat.source",
            --         opts = {
            --             -- this table is passed directly to the proxied completion source
            --             -- as the `option` field in nvim-cmp's source config
            --         },
            --     },
            -- },
        },
    },
    -- LSP servers and clients communicate what features they support through "capabilities".
    --  By default, Neovim support a subset of the LSP specification.
    --  With blink.cmp, Neovim has *more* capabilities which are communicated to the LSP servers.
    --  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
    --
    -- This can vary by config, but in-general for nvim-lspconfig:
    {
        "neovim/nvim-lspconfig",
        dependencies = { "saghen/blink.cmp" },
        config = function(_, opts)
            local lspconfig = require "lspconfig"
            for server, config in pairs(opts.servers or {}) do
                config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
                lspconfig[server].setup(config)
            end
        end,
    },
    -- { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- adapted from https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/ui/mini-animate.lua
    -- {
    --     "echasnovski/mini.animate",
    --     recommended = true,
    --     event = "VeryLazy",
    --     opts = function()
    --         -- don't use animate when scrolling with the mouse
    --         local mouse_scrolled = false
    --         for _, scroll in ipairs { "Up", "Down" } do
    --             local key = "<ScrollWheel" .. scroll .. ">"
    --             vim.keymap.set({ "", "i" }, key, function()
    --                 mouse_scrolled = true
    --                 return key
    --             end, { expr = true })
    --         end

    --         vim.api.nvim_create_autocmd("FileType", {
    --             pattern = "grug-far",
    --             callback = function()
    --                 vim.b.minianimate_disable = true
    --             end,
    --         })

    --         -- LazyVim.toggle.map("<leader>ua", {
    --         --     name = "Mini Animate",
    --         --     get = function()
    --         --         return not vim.g.minianimate_disable
    --         --     end,
    --         --     set = function(state)
    --         --         vim.g.minianimate_disable = not state
    --         --     end,
    --         -- })

    --         local animate = require "mini.animate"
    --         return {
    --             resize = {
    --                 timing = animate.gen_timing.linear { duration = 50, unit = "total" },
    --             },
    --             scroll = {
    --                 timing = animate.gen_timing.linear { duration = 150, unit = "total" },
    --                 subscroll = animate.gen_subscroll.equal {
    --                     predicate = function(total_scroll)
    --                         if mouse_scrolled then
    --                             mouse_scrolled = false
    --                             return false
    --                         end
    --                         return total_scroll > 1
    --                     end,
    --                 },
    --             },
    --         }
    --     end,
    -- },
    -- -- https://gronskiy.com/posts/2023-03-26-copy-via-vim-tmux-ssh/
    -- {
    --     "ojroques/nvim-osc52",
    --     config = function()
    --         require("osc52").setup {
    --             max_length = 0, -- Maximum length of selection (0 for no limit)
    --             silent = false, -- Disable message on successful copy
    --             trim = false, -- Trim surrounding whitespaces before copy
    --         }
    --         local function copy()
    --             if (vim.v.event.operator == "y" or vim.v.event.operator == "d") and vim.v.event.regname == "" then
    --                 require("osc52").copy_register ""
    --             end
    --         end

    --         vim.api.nvim_create_autocmd("TextYankPost", { callback = copy })
    --     end,
    -- },
    -- {
    --     "stevearc/oil.nvim",
    --     config = function()
    --         require("oil").setup {
    --             float = {
    --                 border = "rounded",
    --                 -- max_width = 30,
    --                 -- max_height = 30,
    --                 -- override the layout to be on the left top corner
    --                 -- override = function()
    --                 --     return {
    --                 --         relative = "editor",
    --                 --         width = 30,
    --                 --         height = 30,
    --                 --         row = 0,
    --                 --         col = 0,
    --                 --     }
    --                 -- end,
    --             },
    --         }
    --     end,
    --     -- Optional dependencies
    --     dependencies = { { "echasnovski/mini.icons", opts = {} } },
    --     -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
    --     keys = {
    --         -- map leader o to oil open_float
    --         {
    --             "<leader>o",
    --             function()
    --                 require("oil").open_float()
    --             end,
    --             desc = "Oil - Open Float",
    --         },
    --     },
    -- },
    -- https://www.lazyvim.org/configuration/recipes#supertab
    -- {
    --     "hrsh7th/nvim-cmp",
    --     ---@param opts cmp.ConfigSchema
    --     opts = function()
    --         local has_words_before = function()
    --             unpack = unpack or table.unpack
    --             local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    --             return col ~= 0
    --                 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
    --         end

    --         local cmp = require "cmp"

    --         opts.mapping = vim.tbl_extend("force", opts.mapping, {
    --             ["<Tab>"] = cmp.mapping(function(fallback)
    --                 if cmp.visible() then
    --                     -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
    --                     cmp.select_next_item()
    --                 elseif vim.snippet.active { direction = 1 } then
    --                     vim.schedule(function()
    --                         vim.snippet.jump(1)
    --                     end)
    --                 elseif has_words_before() then
    --                     cmp.complete()
    --                 else
    --                     fallback()
    --                 end
    --             end, { "i", "s" }),
    --             ["<S-Tab>"] = cmp.mapping(function(fallback)
    --                 if cmp.visible() then
    --                     cmp.select_prev_item()
    --                 elseif vim.snippet.active { direction = -1 } then
    --                     vim.schedule(function()
    --                         vim.snippet.jump(-1)
    --                     end)
    --                 else
    --                     fallback()
    --                 end
    --             end, { "i", "s" }),
    --         })
    --     end,
    -- },
    {
        "j-hui/fidget.nvim",
        opts = {
            -- options
        },
    },
    -- { "lewis6991/satellite.nvim" },
    {
        "kentookura/forester.nvim",
        -- before = { "nvim-cmp" },
        -- branch = "36-installation-and-initialization",
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
        keys = {
            { "<localleader>n", "<cmd>Forester new<cr>", desc = "Forester - New" },
            { "<localleader>b", "<cmd>Forester browse<cr>", desc = "Forester - Browse" },
            { "<localleader>l", "<cmd>Forester link_new<cr>", desc = "Forester - Link New" },
            { "<localleader>t", "<cmd>Forester transclude_new<cr>", desc = "Forester - Transclude New" },
            {
                "<localleader>c",
                function()
                    local cmd = "just new"
                    local prefix = vim.fn.input "Enter prefix: "
                    if prefix ~= "" then
                        cmd = cmd .. " " .. prefix
                    else
                        cmd = cmd .. " uts"
                    end
                    local file = io.popen(cmd):read "*a"
                    vim.cmd("e " .. file)
                end,
                desc = "Forester - New from Command",
            },
        },
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
        config = function()
            vim.g.rustaceanvim = {
                -- server = {
                --     on_attach = require("lvim.lsp").common_on_attach,
                -- },
                server = {
                    default_settings = {
                        -- rust-analyzer language server configuration
                        ["rust-analyzer"] = {
                            checkOnSave = {
                                enable = true,
                                command = "clippy",
                            },
                            cargo = {
                                buildScripts = {
                                    enable = false,
                                },
                            },
                            -- procMacro = {
                            --     enable = false,
                            -- },
                            cachePriming = {
                                enable = true,
                                numThreads = 4,
                            },
                        },
                    },
                },
            }
        end,
    },
    {
        "github/copilot.vim",
        event = "VeryLazy",
    },
    -- {
    --     "zbirenbaum/copilot.lua",
    --     cmd = "Copilot",
    --     event = "InsertEnter",
    --     config = function()
    --         require("copilot").setup {
    --             suggestion = {
    --                 auto_trigger = true,
    --                 keymap = {
    --                     -- but this has made the normal tab not working
    --                     accept = "<Tab>",
    --                     accept_word = false,
    --                     accept_line = false,
    --                     next = "<M-]>",
    --                     prev = "<M-[>",
    --                     dismiss = "<S-Tab>",
    --                 },
    --             },
    --         }
    --     end,
    -- },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        event = "VeryLazy",
        branch = "canary",
        dependencies = {
            -- { "zbirenbaum/copilot.lua" },
            { "github/copilot.vim" },
            { "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        build = "make tiktoken", -- Only on MacOS or Linux
        opts = {
            -- debug = true, -- Enable debugging
            -- See Configuration section for rest
            -- window = {
            --     layout = "float",
            --     relative = "cursor",
            --     width = 1,
            --     height = 0.4,
            --     row = 1,
            -- },
        },
        -- {
        --     "hrsh7th/nvim-cmp",
        --     dependencies = { "hrsh7th/cmp-emoji" },
        --     ---@param opts cmp.ConfigSchema
        --     opts = function(_, opts)
        --         table.insert(opts.sources, { name = "emoji" })
        --         local cmp = require "cmp"
        --         -- table.insert(cmp.mapping.preset, { "<C-Tab>", cmp.mapping.confirm { select = true } })
        --         local has_words_before = function()
        --             unpack = unpack or table.unpack
        --             local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        --             return col ~= 0
        --                 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
        --         end
        --         opts.mapping = vim.tbl_extend("force", opts.mapping, {
        --             ["<Tab>"] = cmp.mapping(function(fallback)
        --                 local copilot_ok, copilot_suggestion = pcall(require, "copilot.suggestion")
        --                 if vim.snippet.active { direction = 1 } then
        --                     vim.schedule(function()
        --                         vim.snippet.jump(1)
        --                     end)
        --                 elseif copilot_ok and copilot_suggestion.is_visible() then
        --                     copilot_suggestion.accept()
        --                 elseif has_words_before() then
        --                     cmp.complete()
        --                 else
        --                     fallback()
        --                 end
        --             end, { "i", "s" }),
        --             ["<S-Tab>"] = cmp.mapping(function(fallback)
        --                 local copilot_ok, copilot_suggestion = pcall(require, "copilot.suggestion")
        --                 if vim.snippet.active { direction = -1 } then
        --                     vim.schedule(function()
        --                         vim.snippet.jump(-1)
        --                     end)
        --                 elseif copilot_ok and copilot_suggestion.is_visible() then
        --                     copilot_suggestion.next()
        --                 else
        --                     fallback()
        --                 end
        --             end, { "i", "s" }),
        --         })
        --     end,
        -- },

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
            {
                "<leader>ae",
                mode = "x",
                "<cmd>'<,'>CopilotChatExplain<cr>",
                desc = "CopilotChat - Explain code",
            },
            {
                "<leader>at",
                mode = "x",
                "<cmd>'<,'>CopilotChatTests<cr>",
                desc = "CopilotChat - Generate tests",
            },
            {
                "<leader>ar",
                mode = "x",
                "<cmd>'<,'>CopilotChatReview<cr>",
                desc = "CopilotChat - Review code",
            },
            {
                "<leader>aR",
                mode = "x",
                "<cmd>'<,'>CopilotChatRefactor<cr>",
                desc = "CopilotChat - Refactor code",
            },
            {
                "<leader>an",
                mode = "x",
                "<cmd>'<,'>CopilotChatBetterNamings<cr>",
                desc = "CopilotChat - Better Naming",
            },
            {
                "<leader>ao",
                mode = "x",
                "<cmd>'<,'>CopilotChatOptimize<cr>",
                desc = "CopilotChat - Optimize code",
            },
            { "<leader>ad", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
            { "<leader>af", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "CopilotChat - Fix Diagnostic" },
            { "<leader>al", "<cmd>CopilotChatReset<cr>", desc = "CopilotChat - Clear buffer and chat history" },
            { "<leader>aa", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
            {
                "<leader>aa",
                mode = "x",
                function()
                    require("CopilotChat").ask("Let's discuss the following", {
                        selection = require("CopilotChat.select").visual,
                    })
                    -- local actions = require "CopilotChat.actions"
                    -- actions.pick(actions.prompt_actions {
                    --     selection = require("CopilotChat.select").visual,
                    -- })
                end,
                desc = "CopilotChat - for selection",
            },
            { "<leader>a?", "<cmd>CopilotChatModels<cr>", desc = "CopilotChat - Select Models" },
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
        },
    },
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            -- "hrsh7th/nvim-cmp", -- Optional: For using slash commands and variables in the chat buffer
            "nvim-telescope/telescope.nvim", -- Optional: For using slash commands
            { "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves `vim.ui.select`
            { "echasnovski/mini.diff", version = false },
        },
        config = function()
            require("codecompanion").setup {
                display = {
                    diff = {
                        provider = "mini_diff",
                    },
                },
                strategies = {
                    chat = {
                        -- adapter = "copilot",
                        adapter = "xai",
                    },
                    inline = {
                        -- adapter = "copilot",
                        adapter = "xai",
                    },
                },
            }
        end,
        keys = {
            -- use <C-z> to trigger CodeCompanion for both n and v
            { "<localleader>z", mode = "n", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion - Inline" },
            { "<localleader>z", mode = "v", "<cmd>'<,'>CodeCompanion<cr>", desc = "CodeCompanion - Inline" },
            { "<C-a>", mode = "n", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion - Actions" },
            { "<C-a>", mode = "v", "<cmd>'<,'>CodeCompanionActions<cr>", desc = "CodeCompanion - Actions" },
            { "<localleader>a", mode = "n", "<cmd>CodeCompanionChat Toggle<cr>", desc = "CodeCompanion - Chat Toggle" },
            {
                "<localleader>a",
                mode = "v",
                "<cmd>'<,'>CodeCompanionChat Toggle<cr>",
                desc = "CodeCompanion - Chat Toggle",
            },
            { "ga", mode = "v", "<cmd>CodeCompanionChat Add<cr>", desc = "CodeCompanion - Chat Add" },
        },
    },
    {
        "frankroeder/parrot.nvim",
        dependencies = { "ibhagwan/fzf-lua", "nvim-lua/plenary.nvim" }, -- "rcarriga/nvim-notify" },
        -- optionally include "rcarriga/nvim-notify" for beautiful notifications
        event = "VeryLazy",
        lazy = false,
        config = function(_, opts)
            -- require("notify").setup {
            --     background_colour = "#000000",
            --     render = "compact",
            --     -- top_down = false,
            -- }
            require("parrot").setup(opts)
        end,
        opts = {
            -- Providers must be explicitly added to make them available.
            providers = {
                -- anthropic = {
                --     api_key = os.getenv "ANTHROPIC_API_KEY",
                -- },
                -- gemini = {
                --     api_key = os.getenv "GEMINI_API_KEY",
                -- },
                -- groq = {
                --     api_key = os.getenv "GROQ_API_KEY",
                -- },
                -- mistral = {
                --     api_key = os.getenv "MISTRAL_API_KEY",
                -- },
                -- pplx = {
                --     api_key = os.getenv "PERPLEXITY_API_KEY",
                -- },
                -- -- provide an empty list to make provider available (no API key required)
                -- ollama = {},
                -- openai = {
                --     api_key = os.getenv "OPENAI_API_KEY",
                -- },
                github = {
                    api_key = os.getenv "GITHUB_TOKEN",
                },
                -- nvidia = {
                --     api_key = os.getenv "NVIDIA_API_KEY",
                -- },
                -- xai = {
                --     api_key = os.getenv "XAI_API_KEY",
                -- },
            },
            user_input_ui = "buffer",
            online_model_selection = true,
            command_auto_select_response = true,
            enable_spinner = false,
            hooks = {
                Complete = function(prt, params)
                    local template = [[
        I have the following code from {{filename}}:

        ```{{filetype}}
        {{selection}}
        ```

        Please finish the code above carefully and logically.
        Respond just with the snippet of code that should be inserted."
        ]]
                    local model_obj = prt.get_model "command"
                    prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
                end,
                CompleteFullContext = function(prt, params)
                    local template = [[
        I have the following code from {{filename}}:

        ```{{filetype}}
        {filecontent}}
        ```

        Please look at the following section specifically:
        ```{{filetype}}
        {{selection}}
        ```

        Please finish the code above carefully and logically.
        Respond just with the snippet of code that should be inserted.
        ]]
                    local model_obj = prt.get_model "command"
                    prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
                end,
                CompleteMultiContext = function(prt, params)
                    local template = [[
        I have the following code from {{filename}} and other realted files:

        ```{{filetype}}
        {{multifilecontent}}
        ```

        Please look at the following section specifically:
        ```{{filetype}}
        {{selection}}
        ```

        Please finish the code above carefully and logically.
        Respond just with the snippet of code that should be inserted.
        ]]
                    local model_obj = prt.get_model "command"
                    prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
                end,
                Explain = function(prt, params)
                    local template = [[
        Your task is to take the code snippet from {{filename}} and explain it with gradually increasing complexity.
        Break down the code's functionality, purpose, and key components.
        The goal is to help the reader understand what the code does and how it works.

        ```{{filetype}}
        {{selection}}
        ```

        Use the markdown format with codeblocks and inline code.
        Explanation of the code above:
        ]]
                    local model = prt.get_model "command"
                    prt.logger.info("Explaining selection with model: " .. model.name)
                    prt.Prompt(params, prt.ui.Target.new, model, nil, template)
                end,
                FixBugs = function(prt, params)
                    local template = [[
        You are an expert in {{filetype}}.
        Fix bugs in the below code from {{filename}} carefully and logically:
        Your task is to analyze the provided {{filetype}} code snippet, identify
        any bugs or errors present, and provide a corrected version of the code
        that resolves these issues. Explain the problems you found in the
        original code and how your fixes address them. The corrected code should
        be functional, efficient, and adhere to best practices in
        {{filetype}} programming.

        ```{{filetype}}
        {{selection}}
        ```

        Fixed code:
        ]]
                    local model_obj = prt.get_model "command"
                    prt.logger.info("Fixing bugs in selection with model: " .. model_obj.name)
                    prt.Prompt(params, prt.ui.Target.new, model_obj, nil, template)
                end,
                Optimize = function(prt, params)
                    local template = [[
        You are an expert in {{filetype}}.
        Your task is to analyze the provided {{filetype}} code snippet and
        suggest improvements to optimize its performance. Identify areas
        where the code can be made more efficient, faster, or less
        resource-intensive. Provide specific suggestions for optimization,
        along with explanations of how these changes can enhance the code's
        performance. The optimized code should maintain the same functionality
        as the original code while demonstrating improved efficiency.

        ```{{filetype}}
        {{selection}}
        ```

        Optimized code:
        ]]
                    local model_obj = prt.get_model "command"
                    prt.logger.info("Optimizing selection with model: " .. model_obj.name)
                    prt.Prompt(params, prt.ui.Target.new, model_obj, nil, template)
                end,
                UnitTests = function(prt, params)
                    local template = [[
        I have the following code from {{filename}}:

        ```{{filetype}}
        {{selection}}
        ```

        Please respond by writing table driven unit tests for the code above.
        ]]
                    local model_obj = prt.get_model "command"
                    prt.logger.info("Creating unit tests for selection with model: " .. model_obj.name)
                    prt.Prompt(params, prt.ui.Target.enew, model_obj, nil, template)
                end,
                Debug = function(prt, params)
                    local template = [[
        I want you to act as {{filetype}} expert.
        Review the following code, carefully examine it, and report potential
        bugs and edge cases alongside solutions to resolve them.
        Keep your explanation short and to the point:

        ```{{filetype}}
        {{selection}}
        ```
        ]]
                    local model_obj = prt.get_model "command"
                    prt.logger.info("Debugging selection with model: " .. model_obj.name)
                    prt.Prompt(params, prt.ui.Target.enew, model_obj, nil, template)
                end,
                CommitMsg = function(prt, params)
                    local futils = require "parrot.file_utils"
                    if futils.find_git_root() == "" then
                        prt.logger.warning "Not in a git repository"
                        return
                    else
                        local template = [[
          I want you to act as a commit message generator. I will provide you
          with information about the task and the prefix for the task code, and
          I would like you to generate an appropriate commit message using the
          conventional commit format. Do not write any explanations or other
          words, just reply with the commit message.
          Start with a short headline as summary but then list the individual
          changes in more detail.

          Here are the changes that should be considered by this message:
          ]] .. vim.fn.system "git diff --no-color --no-ext-diff --staged"
                        local model_obj = prt.get_model "command"
                        prt.Prompt(params, prt.ui.Target.append, model_obj, nil, template)
                    end
                end,
                SpellCheck = function(prt, params)
                    local chat_prompt = [[
        Your task is to take the text provided and rewrite it into a clear,
        grammatically correct version while preserving the original meaning
        as closely as possible. Correct any spelling mistakes, punctuation
        errors, verb tense issues, word choice problems, and other
        grammatical mistakes.
        ]]
                    prt.ChatNew(params, chat_prompt)
                end,
                CodeConsultant = function(prt, params)
                    local chat_prompt = [[
          Your task is to analyze the provided {{filetype}} code and suggest
          improvements to optimize its performance. Identify areas where the
          code can be made more efficient, faster, or less resource-intensive.
          Provide specific suggestions for optimization, along with explanations
          of how these changes can enhance the code's performance. The optimized
          code should maintain the same functionality as the original code while
          demonstrating improved efficiency.

          Here is the code
          ```{{filetype}}
          {{filecontent}}
          ```
        ]]
                    prt.ChatNew(params, chat_prompt)
                end,
                ProofReader = function(prt, params)
                    local chat_prompt = [[
        I want you to act as a proofreader. I will provide you with texts and
        I would like you to review them for any spelling, grammar, or
        punctuation errors. Once you have finished reviewing the text,
        provide me with any necessary corrections or suggestions to improve the
        text. Highlight the corrected fragments (if any) using markdown backticks.

        When you have done that subsequently provide me with a slightly better
        version of the text, but keep close to the original text.

        Finally provide me with an ideal version of the text.

        Whenever I provide you with text, you reply in this format directly:

        ## Corrected text:

        {corrected text, or say "NO_CORRECTIONS_NEEDED" instead if there are no corrections made}

        ## Slightly better text

        {slightly better text}

        ## Ideal text

        {ideal text}
        ]]
                    prt.ChatNew(params, chat_prompt)
                end,
            },
        },
        keys = {
            { "<leader>pr", "<cmd>'<,'>PrtRewrite<cr>", desc = "PtrRewrite", mode = "x" },
            { "<leader>pp", "<cmd>'<,'>PrtImplement<cr>", desc = "PtrImplement", mode = "x" },
            { "<leader>pn", "<cmd>'<,'>PrtVnew<cr>", desc = "PtrVnew", mode = "x" },
            { "<leader>pn", "<cmd>PrtVnew<cr>", desc = "PtrVnew", mode = "n" },
        },
    },
    -- {
    --     "ddzero2c/aider.nvim",
    --     opts = {
    --         {
    --             command = "aider", -- Path to aider command
    --             model = "github/gpt-4o",
    --             -- model = "sonnet", -- AI model to use
    --             mode = "inline", -- Edit mode: 'diff' or 'inline'
    --             -- Floating window options
    --             float_opts = {
    --                 relative = "editor",
    --                 width = 0.8, -- 80% of editor width
    --                 height = 0.8, -- 80% of editor height
    --                 style = "minimal",
    --                 border = "rounded",
    --                 title = " Aider ",
    --                 title_pos = "center",
    --             },
    --         },
    --     },
    --     keys = {
    --         { "<leader>po", "<cmd>AiderEdit<cr>", desc = "AiderEdit", mode = "x" },
    --         { "<leader>po", "<cmd>AiderEdit<cr>", desc = "AiderEdit", mode = "n" },
    --     },
    -- },
    -- {
    --     "zbirenbaum/copilot-cmp",
    --     after = {
    --         "copilot.vim",
    --         -- "copilot.lua",
    --         "nvim-cmp",
    --     },
    --     config = function()
    --         require("copilot_cmp").setup()
    --     end,
    -- },
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
            { "<leader>ga", "<cmd>GhActions<cr>", desc = "Open Github Actions" },
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
    -- {
    --     "nvim-pack/nvim-spectre",
    --     event = "BufRead",
    --     config = function()
    --         require("spectre").setup {
    --             use_trouble_qf = true,
    --             default = {
    --                 replace = {
    --                     cmd = "sd",
    --                 },
    --             },
    --         }
    --     end,
    --     keys = {
    --         { "<leader>ss", "<cmd>lua require('spectre').toggle()<cr>", desc = "Toggle Spectre" },
    --         {
    --             "<leader>sw",
    --             "<cmd>lua require('spectre').open_visual({select_word=true})<cr>",
    --             desc = "Spectre (word)",
    --         },
    --     },
    -- },
    {
        "MagicDuck/grug-far.nvim",
        config = function()
            require("grug-far").setup {
                -- options, see Configuration section below
                -- there are no required options atm
                -- engine = 'ripgrep' is default, but 'astgrep' can be specified
            }
        end,
        keys = {
            {
                "<leader>ss",
                "<cmd>lua require('grug-far').toggle_instance({instanceName='default'})<cr>",
                desc = "Toggle Spectre",
            },
            {
                "<leader>sw",
                "<cmd>lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })<cr>",
                desc = "Spectre (word)",
            },
        },
    },
    -- {
    --     "neovim/nvim-lspconfig",
    --     dependencies = {
    --         {
    --             "SmiteshP/nvim-navbuddy",
    --             dependencies = {
    --                 "SmiteshP/nvim-navic",
    --                 "MunifTanjim/nui.nvim",
    --             },
    --             opts = { lsp = { auto_attach = true } },
    --         },
    --     },
    --     -- your lsp config or other stuff
    -- },
    -- play also https://www.vim-hero.com/lessons/basic-movement
    -- { "ThePrimeagen/vim-be-good" }
    {
        "iamcco/markdown-preview.nvim",
        build = "cd app && npm install",
        ft = "markdown",
        config = function()
            vim.g.mkdp_auto_start = 1
        end,
        keys = {
            { "<leader>mm", "<cmd>MarkdownPreviewToggle<cr>", desc = "Toggle Markdown Preview" },
        },
    },
    {
        "nvchad/showkeys",
        cmd = "ShowkeysToggle",
        opts = {
            timeout = 1,
            maxkeys = 7,
            show_count = true,
            excluded_modes = { "i" },
            position = "top-right",
            winopts = {
                focusable = false,
                relative = "editor",
                style = "minimal",
                border = "rounded",
                height = 1,
                row = 1,
                col = 0,
            },
        },
        keys = {
            { "<leader>kk", "<cmd>ShowkeysToggle<cr>", desc = "Show Keys" },
        },
    },
    -- {
    --     "4513ECHO/nvim-keycastr",
    --     init = function()
    --         local enabled = false
    --         local config_set = false
    --         vim.keymap.set("n", "<Leader>kk", function()
    --             vim.notify(("%s keycastr"):format(enabled and "Disabling" or "Enabling"))
    --             local keycastr = require "keycastr"
    --             if not config_set then
    --                 keycastr.config.set { win_config = { border = "rounded" }, position = "NE" }
    --                 config_set = true
    --             end
    --             keycastr[enabled and "disable" or "enable"]()
    --             enabled = not enabled
    --         end)
    --     end,
    -- },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" }, -- if you use the mini.nvim suite
        -- dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
        opts = {
            enable = true,
            render_modes = true,
            heading = {
                position = "inline",
                -- border = true,
                -- width = "block",
                -- min_width = 30,
                -- above = "▃",
                -- below = "🬂",
                width = "full",
                -- icons = { "◉ ", "○ ", "✸ ", "✿ " },
                -- backgrounds = { "CursorLine" },
                -- foregrounds = {
                --     "@markup.heading.1.markdown",
                --     "@markup.heading.2.markdown",
                --     "@markup.heading.3.markdown",
                --     "@markup.heading.4.markdown",
                --     "@markup.heading.5.markdown",
                --     "@markup.heading.6.markdown",
                -- },
                -- backgrounds = {
                --     "@text.title.1.markdown",
                --     "@text.title.2.markdown",
                --     "@text.title.3.markdown",
                --     "@text.title.4.markdown",
                --     "@text.title.5.markdown",
                --     "@text.title.6.markdown",
                -- },
                -- border_prefix = true,
                -- border = true,
                -- border_virtual = true,
                -- foregrounds = {
                --     "RenderMarkdownH1",
                --     "RenderMarkdownH2",
                --     "RenderMarkdownH3",
                --     "RenderMarkdownH4",
                --     "RenderMarkdownH5",
                --     "RenderMarkdownH6",
                -- -- },
                -- backgrounds = {
                --     "RenderMarkdownH1",
                --     "RenderMarkdownH2",
                --     "RenderMarkdownH3",
                --     "RenderMarkdownH4",
                --     "RenderMarkdownH5",
                --     "RenderMarkdownH6",
                -- },
            },
        },
        ft = { "markdown", "quarto" },
    },
    -- {
    --     "3rd/image.nvim",
    --     config = function()
    --         require("image").setup {
    --             -- processor = "magick_cli",
    --         }
    --     end,
    -- },
    {
        "vhyrro/luarocks.nvim",
        priority = 1001, -- this plugin needs to run before anything else
        opts = {
            rocks = { "magick" },
        },
    },
    {
        "3rd/image.nvim",
        dependencies = { "luarocks.nvim" },
        config = function()
            require("image").setup {
                backend = "kitty",
                processor = "magick_cli",
                integrations = {
                    markdown = {
                        filetypes = { "markdown", "vimwiki", "quarto" },
                        only_render_image_at_cursor = true,
                    },
                },
            }
            -- ...
        end,
    },
    -- {
    --     "rcarriga/nvim-notify",
    --     keys = {
    --         {
    --             "<leader>un",
    --             function()
    --                 require("notify").dismiss { silent = true, pending = true }
    --             end,
    --             desc = "Dismiss All Notifications",
    --         },
    --     },
    --     opts = {
    --         stages = "static",
    --         timeout = 3000,
    --         max_height = function()
    --             return math.floor(vim.o.lines * 0.75)
    --         end,
    --         max_width = function()
    --             return math.floor(vim.o.columns * 0.75)
    --         end,
    --         on_open = function(win)
    --             vim.api.nvim_win_set_config(win, { zindex = 100 })
    --         end,
    --     },
    --     init = function()
    --         vim.notify = require "notify"
    --     end,
    -- },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    ["cmp.entry.get_documentation"] = true,
                },
            },
            routes = {
                {
                    filter = {
                        event = "msg_show",
                        any = {
                            { find = "%d+L, %d+B" },
                            { find = "; after #%d+" },
                            { find = "; before #%d+" },
                        },
                    },
                    view = "mini",
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
            },
            -- based on https://github.com/folke/noice.nvim/issues/779#issuecomment-2081998250
            views = {
                cmdline_popup = {
                    -- backend = "popup",
                    -- relative = "editor",
                    -- zindex = 200,
                    position = {
                        row = "40%", -- 40% from top of the screen. This will position it almost at the center.
                        col = "50%",
                    },
                    size = {
                        width = 120,
                        height = "auto",
                    },
                    -- win_options = {
                    --     winhighlight = {
                    --         Normal = "NoiceCmdlinePopup",
                    --         FloatTitle = "NoiceCmdlinePopupTitle",
                    --         FloatBorder = "NoiceCmdlinePopupBorder",
                    --         IncSearch = "",
                    --         CurSearch = "",
                    --         Search = "",
                    --     },
                    --     winbar = "",
                    --     foldenable = false,
                    --     cursorline = false,
                    -- },
                },
                popupmenu = {
                    -- relative = 'editor', -- "'cursor'"|"'editor'"|"'win'"
                    position = {
                        row = "auto", -- Popup will show up below the cmdline automatically
                        col = "auto",
                    },
                    size = {
                        width = 120, -- Making this as wide as the cmdline_popup
                        height = "auto",
                    },
                    border = {
                        style = "double", -- 'double'"|"'none'"|"'rounded'"|"'shadow'"|"'single'"|"'solid'
                        padding = { 0, 1 },
                    },
                    win_options = {
                        winhighlight = {
                            Normal = "NoicePopupmenu", -- Normal | NoicePopupmenu
                            FloatBorder = "NoicePopupmenuBorder", -- DiagnosticInfo | NoicePopupmenuBorder
                            CursorLine = "NoicePopupmenuSelected",
                            PmenuMatch = "NoicePopupmenuMatch",
                        },
                    },
                },
            },
            cmdline = {
                -- view = "cmdline",
                view = "cmdline_popup",
            },
        },
        keys = {
            { "<leader>sn", "", desc = "+noice" },
            {
                "<S-Enter>",
                function()
                    require("noice").redirect(vim.fn.getcmdline())
                end,
                mode = "c",
                desc = "Redirect Cmdline",
            },
            {
                "<leader>snl",
                function()
                    require("noice").cmd "last"
                end,
                desc = "Noice Last Message",
            },
            {
                "<leader>snh",
                function()
                    require("noice").cmd "history"
                end,
                desc = "Noice History",
            },
            {
                "<leader>sna",
                function()
                    require("noice").cmd "all"
                end,
                desc = "Noice All",
            },
            {
                "<leader>snd",
                function()
                    require("noice").cmd "dismiss"
                end,
                desc = "Dismiss All",
            },
            {
                "<leader>snt",
                function()
                    require("noice").cmd "nick"
                end,
                desc = "Noice Picker (Telescope/FzfLua)",
            },
            {
                "<c-f>",
                function()
                    if not require("noice.lsp").scroll(4) then
                        return "<c-f>"
                    end
                end,
                silent = true,
                expr = true,
                desc = "Scroll Forward",
                mode = { "i", "n", "s" },
            },
            {
                "<c-b>",
                function()
                    if not require("noice.lsp").scroll(-4) then
                        return "<c-b>"
                    end
                end,
                silent = true,
                expr = true,
                desc = "Scroll Backward",
                mode = { "i", "n", "s" },
            },
        },
        config = function(_, opts)
            -- HACK: noice shows messages from before it was enabled,
            -- but this is not ideal when Lazy is installing plugins,
            -- so clear the messages in this case.
            if vim.o.filetype == "lazy" then
                vim.cmd [[messages clear]]
            end
            require("noice").setup(opts)
        end,
    },
    {
        "folke/persistence.nvim",
        event = "BufReadPre", -- this will only start session saving when an actual file was opened
        opts = {
            -- add any custom options here
        },
        keys = {
            {
                "<leader>rs",
                function()
                    require("persistence").load()
                end,
                "Load the session for the current working directory",
            },
            {
                "<leader>rS",
                function()
                    require("persistence").select()
                end,
                "Select a session to load",
            },
        },
    },
    {
        "hedyhli/outline.nvim",
        lazy = true,
        cmd = { "Outline", "OutlineOpen" },
        keys = { -- Example mapping to toggle outline
            { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
        },
        opts = {
            symbol_folding = {
                autofold_depth = 1,
                auto_unfold = {
                    hovered = true,
                },
            },
            auto_jump = true,
            outline_window = {
                auto_jump = true,
            },
            -- preview_window = {
            --     auto_preview = true,
            -- },
        },
    },
    {
        "stevearc/conform.nvim",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                bib = { "trim_whitespace" },
            },
            format_on_save = {
                -- These options will be passed to conform.format()
                timeout_ms = 500,
                lsp_format = "fallback",
            },
        },
    },
    -- { "neoclide/coc.nvim", branch = "release" },
    -- {
    --     "barreiroleo/ltex_extra.nvim",
    --     branch = "dev",
    --     ft = { "markdown", "tex" },
    --     opts = {
    --         ---@type string[]
    --         -- See https://valentjn.github.io/ltex/supported-languages.html#natural-languages
    --         load_langs = { "en-US" },
    --         ---@type "none" | "fatal" | "error" | "warn" | "info" | "debug" | "trace"
    --         log_level = "none",
    --         ---@type string File's path to load.
    --         -- The setup will normalice it running vim.fs.normalize(path).
    --         -- e.g. subfolder in project root or cwd: ".ltex"
    --         -- e.g. cross project settings:  vim.fn.expand("~") .. "/.local/share/ltex"
    --         path = ".ltex",
    --     },
    -- },
    -- {
    --     "nvchad/ui",
    --     config = function()
    --         require "nvchad"
    --     end,
    -- },
    -- {
    --     "nvchad/base46",
    --     lazy = false,
    --     build = function()
    --         require("base46").load_all_highlights()
    --     end,
    --     opts = {
    --         theme = "onedark",
    --     },
    --     -- config = function()
    --     --     local base46 = require "base46"
    --     -- end,
    -- },
    -- "nvchad/volt",
    -- {
    --     "ThePrimeagen/harpoon",
    --     branch = "harpoon2",
    --     dependencies = { "nvim-lua/plenary.nvim" },
    -- },
    -- {
    --     "dnlhc/glance.nvim",
    --     config = function()
    --         require("glance").setup {
    --             -- your configuration
    --         }
    --     end,
    -- },

    -- {
    --     "Zeioth/hot-reload.nvim",
    --     dependencies = "nvim-lua/plenary.nvim",
    --     event = "BufEnter",
    --     opts = {}
    -- }
}

return plugins
