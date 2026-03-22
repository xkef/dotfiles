return {
  -- Catppuccin colorscheme (matches the `theme` command's terminal palette).
  -- The theme system in lua/theme.lua reads ~/.config/theme/current and applies
  -- the colorscheme + background, so init.lua handles the initial apply.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = { flavour = "auto" },
  },

  -- Smart splits: seamless C-hjkl navigation between tmux panes and nvim splits
  {
    "mrjones2014/smart-splits.nvim",
    keys = {
      {
        "<C-h>",
        function()
          require("smart-splits").move_cursor_left()
        end,
      },
      {
        "<C-j>",
        function()
          require("smart-splits").move_cursor_down()
        end,
      },
      {
        "<C-k>",
        function()
          require("smart-splits").move_cursor_up()
        end,
      },
      {
        "<C-l>",
        function()
          require("smart-splits").move_cursor_right()
        end,
      },
      {
        "<A-h>",
        function()
          require("smart-splits").resize_left()
        end,
      },
      {
        "<A-j>",
        function()
          require("smart-splits").resize_down()
        end,
      },
      {
        "<A-k>",
        function()
          require("smart-splits").resize_up()
        end,
      },
      {
        "<A-l>",
        function()
          require("smart-splits").resize_right()
        end,
      },
    },
  },

  -- Treesitter: syntax highlighting, text objects, and incremental selection.
  -- Parses code into an AST for accurate, language-aware highlighting.
  -- Note: nvim-treesitter removed the configs module; use opts directly.
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml", "markdown" },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Telescope: fuzzy finder for files, grep, buffers, etc.
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
      vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })
    end,
  },

  -- Which-key: shows available keybindings in a popup
  {
    "folke/which-key.nvim",
    event = "VimEnter",
    opts = {},
  },

  -- Gitsigns: git change indicators in the sign column
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },

  -- Mini.nvim: collection of small independent plugins
  {
    "echasnovski/mini.nvim",
    config = function()
      require("mini.ai").setup()
      require("mini.surround").setup()
      require("mini.statusline").setup()
      require("mini.pairs").setup()
    end,
  },
}
