return {
  -- Colorschemes (active theme read from ~/.config/theme/current)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        native_lsp = { enabled = true },
        telescope = { enabled = true },
        treesitter = true,
        lualine = true,
      },
    },
  },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 1000 },
  { "ellisonleao/gruvbox.nvim", lazy = false, priority = 1000 },
  { "shaunsingh/nord.nvim", lazy = false, priority = 1000 },

  -- Tmux navigation
  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },

  -- Lua development (better Neovim API types for lua_ls)
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("mason").setup()

      local capabilities = require("blink.cmp").get_lsp_capabilities()

      require("mason-lspconfig").setup({
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({ capabilities = capabilities })
          end,
          ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
              capabilities = capabilities,
              settings = {
                Lua = { telemetry = { enable = false } },
              },
            })
          end,
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local m = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
          end
          m("gd", vim.lsp.buf.definition, "Go to definition")
          m("gr", vim.lsp.buf.references, "References")
          m("gI", vim.lsp.buf.implementation, "Implementation")
          m("gy", vim.lsp.buf.type_definition, "Type definition")
          m("K", vim.lsp.buf.hover, "Hover")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
          m("<leader>cr", vim.lsp.buf.rename, "Rename")
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end,
      })
    end,
  },

  -- Completion (blink.cmp — Rust-based, replaces nvim-cmp)
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      snippets = { preset = "luasnip" },
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
    },
  },

  -- Auto-format on save
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        sh = { "shfmt" },
        go = { "gofmt" },
        rust = { "rustfmt" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  -- Flash (s/S to jump anywhere on screen)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,            desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end,      desc = "Flash treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,           desc = "Flash remote" },
    },
  },

  -- Auto-close brackets/quotes
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      ensure_installed = {
        "bash", "c", "css", "go", "html", "javascript", "json",
        "lua", "markdown", "python", "rust", "tsx", "typescript",
        "vim", "vimdoc", "yaml",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)

      -- Textobjects
      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")

      vim.keymap.set({ "x", "o" }, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end)
      vim.keymap.set({ "x", "o" }, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end)

      vim.keymap.set("n", "]f", function() ts_move.goto_next_start("@function.outer", "textobjects") end)
      vim.keymap.set("n", "[f", function() ts_move.goto_previous_start("@function.outer", "textobjects") end)
      vim.keymap.set("n", "]c", function() ts_move.goto_next_start("@class.outer", "textobjects") end)
      vim.keymap.set("n", "[c", function() ts_move.goto_previous_start("@class.outer", "textobjects") end)
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>/",  "<cmd>Telescope live_grep<cr>",  desc = "Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",   desc = "Recent files" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>",  desc = "Grep" },
      { "<leader>sG", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
      { "<leader>sr", "<cmd>Telescope resume<cr>",     desc = "Resume search" },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { horizontal = { preview_width = 0.55 } },
        sorting_strategy = "ascending",
        file_ignore_patterns = { "node_modules", ".git/", "target/", "dist/", "build/" },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
          },
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      require("telescope").load_extension("fzf")
    end,
  },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
  },
  {
    "tpope/vim-fugitive",
    cmd = "Git",
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
    },
  },

  -- File navigation
  {
    "stevearc/oil.nvim",
    keys = { { "-", "<cmd>Oil<cr>", desc = "File browser" } },
    opts = { view_options = { show_hidden = true } },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
      { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
    opts = {},
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        globalstatus = true,
        component_separators = "",
        section_separators = "",
        disabled_filetypes = { statusline = { "lazy" } },
      },
      sections = {
        lualine_a = {
          { "mode", fmt = function(s) return s:sub(1, 1) end },
        },
        lualine_b = {
          { "branch", icon = "" },
        },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
          {
            "diagnostics",
            symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
          },
        },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1, symbols = { modified = " ●", readonly = " " } } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    },
  },

  -- Search and replace
  {
    "MagicDuck/grug-far.nvim",
    keys = {
      { "<leader>S",  "<cmd>GrugFar<cr>", desc = "Search and replace" },
      { "<leader>sR", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Search and replace (word)" },
    },
    opts = {},
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },
}
