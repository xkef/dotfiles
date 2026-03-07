return {
  -- Colorschemes (active theme read from ~/.config/theme/current)
  -- All lazy=true: theme.lua calls vim.cmd.colorscheme() which lazy.nvim intercepts
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        native_lsp = { enabled = true },
        treesitter = true,
        lualine = true,
      },
    },
  },
  { "folke/tokyonight.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "shaunsingh/nord.nvim", lazy = true },

  -- Smart split/pane navigation (Neovim + tmux, replaces vim-tmux-navigator)
  {
    "mrjones2014/smart-splits.nvim",
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end },
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

  -- LSP (Neovim 0.11 style: vim.lsp.config + automatic_enable)
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

      -- Default capabilities for all servers
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Server-specific overrides
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = { telemetry = { enable = false } },
        },
      })

      require("mason-lspconfig").setup({ automatic_enable = true })

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
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "r", mode = "o",               function() require("flash").remote() end,      desc = "Flash remote" },
    },
  },

  -- Snacks (picker replaces telescope; lazygit replaces vim-fugitive)
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker  = { enabled = true },
      lazygit = { enabled = true },
      -- opt-out of everything else
      bigfile      = { enabled = false },
      dashboard    = { enabled = false },
      indent       = { enabled = false },
      input        = { enabled = false },
      notifier     = { enabled = false },
      quickfile    = { enabled = false },
      scope        = { enabled = false },
      scroll       = { enabled = false },
      statuscolumn = { enabled = false },
      terminal     = { enabled = false },
      words        = { enabled = false },
    },
    keys = {
      { "<leader>ff", function() Snacks.picker.files() end,     desc = "Find files" },
      { "<leader>/",  function() Snacks.picker.grep() end,      desc = "Grep" },
      { "<leader>fb", function() Snacks.picker.buffers() end,   desc = "Buffers" },
      { "<leader>fh", function() Snacks.picker.help() end,      desc = "Help" },
      { "<leader>fr", function() Snacks.picker.recent() end,    desc = "Recent files" },
      { "<leader>sg", function() Snacks.picker.grep() end,      desc = "Grep" },
      { "<leader>sG", function() Snacks.picker.grep_word() end, desc = "Grep word under cursor" },
      { "<leader>sr", function() Snacks.picker.resume() end,    desc = "Resume search" },
      { "<leader>gs", function() Snacks.lazygit() end,          desc = "Lazygit" },
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

  -- Git signs + blame
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local map = function(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end
        map("n", "]h", gs.next_hunk, "Next hunk")
        map("n", "[h", gs.prev_hunk, "Prev hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hd", gs.diffthis, "Diff buffer")
      end,
    },
  },

  -- File navigation
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Tree explorer" },
      { "-", "<cmd>NvimTreeToggle<cr>", desc = "File browser" },
    },
    opts = {
      renderer = {
        group_empty = true,
        indent_markers = { enable = true },
        icons = {
          show = { folder_arrow = false },
        },
      },
      view = {
        width = 35,
        side = "left",
      },
      filters = { dotfiles = false },
      actions = {
        open_file = { quit_on_open = true },
      },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        local function map(key, fn, desc)
          vim.keymap.set("n", key, fn, { buffer = bufnr, desc = desc })
        end
        api.config.mappings.default_on_attach(bufnr)
        map("l", api.node.open.edit, "Open")
        map("h", api.node.navigate.parent_close, "Close folder")
        map("q", api.tree.close, "Close")
        map("<C-v>", api.node.open.vertical, "Open in vsplit")
        map("<C-s>", api.node.open.horizontal, "Open in split")
      end,
    },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end,                                              desc = "Harpoon add" },
      { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,           desc = "Harpoon menu" },
      { "<leader>1",  function() require("harpoon"):list():select(1) end,                                          desc = "Harpoon 1" },
      { "<leader>2",  function() require("harpoon"):list():select(2) end,                                          desc = "Harpoon 2" },
      { "<leader>3",  function() require("harpoon"):list():select(3) end,                                          desc = "Harpoon 3" },
      { "<leader>4",  function() require("harpoon"):list():select(4) end,                                          desc = "Harpoon 4" },
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
        lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
        lualine_b = { { "branch", icon = "" } },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
          { "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
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
      { "<leader>S",  "<cmd>GrugFar<cr>",                                                                            desc = "Search and replace" },
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
