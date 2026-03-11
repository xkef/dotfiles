return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "css",
        "go",
        "html",
        "java",
        "javascript",
        "json",
        "lua",
        "markdown",
        "python",
        "rust",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)

      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")

      vim.keymap.set({ "x", "o" }, "af", function()
        ts_select.select_textobject("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "if", function()
        ts_select.select_textobject("@function.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ac", function()
        ts_select.select_textobject("@class.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ic", function()
        ts_select.select_textobject("@class.inner", "textobjects")
      end)

      vim.keymap.set("n", "]f", function()
        ts_move.goto_next_start("@function.outer", "textobjects")
      end)
      vim.keymap.set("n", "[f", function()
        ts_move.goto_previous_start("@function.outer", "textobjects")
      end)
      vim.keymap.set("n", "]c", function()
        ts_move.goto_next_start("@class.outer", "textobjects")
      end)
      vim.keymap.set("n", "[c", function()
        ts_move.goto_previous_start("@class.outer", "textobjects")
      end)
    end,
  },
}
