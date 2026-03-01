-- Editor enhancements — deep fzf integration
return {
  -- fzf-native for telescope (compiled C sorter, dramatically faster)
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    config = function()
      require("telescope").load_extension("fzf")
    end,
  },

  -- Telescope overrides with fzf-native
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-telescope/telescope-fzf-native.nvim" },
    keys = {
      { "<leader>/",  "<cmd>Telescope live_grep<cr>",                 desc = "Grep (project)" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>",                 desc = "Grep (project)" },
      { "<leader>sG", "<cmd>Telescope grep_string<cr>",               desc = "Grep word under cursor" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Fuzzy find (buffer)" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>",           desc = "Command history" },
      { "<leader>sC", "<cmd>Telescope commands<cr>",                  desc = "Commands" },
      { "<leader>sm", "<cmd>Telescope marks<cr>",                     desc = "Marks" },
      { "<leader>sR", "<cmd>Telescope resume<cr>",                    desc = "Resume last search" },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = { preview_width = 0.55 },
          width = 0.87,
          height = 0.80,
        },
        sorting_strategy = "ascending",
        prompt_prefix = "   ",
        selection_caret = "  ",
        file_ignore_patterns = {
          "node_modules",
          ".git/",
          "target/",
          "dist/",
          "build/",
          "__pycache__",
          "%.lock",
        },
        mappings = {
          i = {
            ["<C-j>"] = "move_selection_next",
            ["<C-k>"] = "move_selection_previous",
            ["<C-d>"] = "preview_scrolling_down",
            ["<C-u>"] = "preview_scrolling_up",
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    },
  },

  -- Harpoon for quick file navigation
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end,     desc = "Harpoon add" },
      { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
      { "<leader>1",  function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2",  function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3",  function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4",  function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
    opts = {},
  },

  -- Oil.nvim for file management
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = false,
      view_options = {
        show_hidden = true,
      },
    },
  },

  -- Zen mode for focused editing
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>zz", "<cmd>ZenMode<cr>", desc = "Zen Mode" },
    },
    opts = {
      window = { width = 120 },
    },
  },
}
