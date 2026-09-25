return {
  {
    "mrjones2014/smart-splits.nvim",
    -- Loads at startup to set the IS_NVIM user var, which WezTerm's leader
    -- h/j/k/l reads to hand the key to Neovim. A lazy load leaves it unset
    -- until the first move.
    lazy = false,
    keys = (function()
      local ss = "smart-splits"
      local keys = {}
      for _, m in ipairs({
        { "<C-h>", "move_cursor_left" },
        { "<C-j>", "move_cursor_down" },
        { "<C-k>", "move_cursor_up" },
        { "<C-l>", "move_cursor_right" },
        { "<A-h>", "resize_left" },
        { "<A-j>", "resize_down" },
        { "<A-k>", "resize_up" },
        { "<A-l>", "resize_right" },
      }) do
        keys[#keys + 1] = {
          m[1],
          function()
            require(ss)[m[2]]()
          end,
        }
      end
      return keys
    end)(),
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
        },
        previewers = {
          diff = {
            builtin = false,
            cmd = { "git", "diff", "--no-ext-diff" },
          },
        },
      },
    },
    init = function()
      -- Hide hunk headers in the Snacks diff renderer.
      local ok, diff = pcall(require, "snacks.picker.util.diff")
      if ok and diff.render then
        local orig = diff.render
        diff.render = function(buf, ns, d, opts)
          opts = vim.tbl_deep_extend("force", opts or {}, { hunk_header = false })
          return orig(buf, ns, d, opts)
        end
      end
    end,
  },

  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "lewis6991/async.nvim" },
  },
}
