-- Labeled jumps, like easymotion or hop. catppuccin integrates with flash,
-- see colorschemes.lua.
return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        search = { enabled = false },
        char = { enabled = true, jump_labels = true },
      },
    },
    keys = {
      -- @key nvim :: s :: Flash jump (labeled)
      {
        "s",
        function()
          require("flash").jump()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash",
      },
      -- @key nvim :: S :: Flash treesitter (jump to syntax node)
      {
        "S",
        function()
          require("flash").treesitter()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash Treesitter",
      },
      {
        "r",
        function()
          require("flash").remote()
        end,
        mode = "o",
        desc = "Remote Flash",
      },
    },
  },
}
