return {
  {
    "mrjones2014/smart-splits.nvim",
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
      -- Patch Snacks diff renderer to hide hunk headers
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
