return {
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
    },
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
      lazygit = { enabled = true },
      image = { enabled = true },
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      indent = { enabled = false },
      input = { enabled = false },
      notifier = { enabled = false },
      quickfile = { enabled = false },
      scope = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = { enabled = false },
      terminal = { enabled = true, win = { style = "float" } },
      words = { enabled = false },
    },
    keys = {
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },
      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sG",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Grep word under cursor",
      },
      {
        "<leader>sr",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume search",
      },
      {
        "<leader>gs",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>?",
        function()
          require("which-key").show()
        end,
        desc = "Which-key (all keybindings)",
      },
      {
        "<leader>t",
        function()
          Snacks.terminal()
        end,
        desc = "Floating terminal",
      },
    },
  },

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
        side = "right",
      },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      filters = { dotfiles = false },
      actions = {
        open_file = { quit_on_open = true },
        change_dir = { restrict_above_cwd = true },
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
      {
        "<leader>ha",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon add",
      },
      {
        "<leader>hh",
        function()
          require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
        end,
        desc = "Harpoon menu",
      },
      {
        "<leader>1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Harpoon 1",
      },
      {
        "<leader>2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Harpoon 2",
      },
      {
        "<leader>3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Harpoon 3",
      },
      {
        "<leader>4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Harpoon 4",
      },
    },
    config = function()
      require("harpoon"):setup()
    end,
  },
}
