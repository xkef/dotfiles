return {
  {
    "mrjones2014/smart-splits.nvim",
    keys = {
      -- Navigation (works across tmux panes too via smart-splits tmux integration)
      { "<C-h>", function() require("smart-splits").move_cursor_left() end },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end },
      -- Resize
      { "<A-h>", function() require("smart-splits").resize_left() end },
      { "<A-j>", function() require("smart-splits").resize_down() end },
      { "<A-k>", function() require("smart-splits").resize_up() end },
      { "<A-l>", function() require("smart-splits").resize_right() end },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
        },
      },
    },
  },

  {
    "alexpasmantier/tv.nvim",
    dependencies = { "alexpasmantier/television" },
    keys = {
      { "<leader>tt", "<cmd>Tv<cr>", desc = "Television (channel picker)" },
      { "<leader>tg", "<cmd>Tv git-log<cr>", desc = "Television git log" },
      { "<leader>tb", "<cmd>Tv git-branch<cr>", desc = "Television git branches" },
      { "<leader>td", "<cmd>Tv git-diff<cr>", desc = "Television git diff" },
      { "<leader>te", "<cmd>Tv env<cr>", desc = "Television env vars" },
    },
    cmd = { "Tv" },
    opts = {},
  },
}
