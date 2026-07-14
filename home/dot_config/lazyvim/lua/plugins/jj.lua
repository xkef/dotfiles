local is_pure_jj = vim.fs.root(0, ".jj") ~= nil and vim.fs.root(0, ".git") == nil

return {
  {
    "nicolasgb/jj.nvim",
    version = "*",
    dependencies = {
      "folke/snacks.nvim",
      "sindrets/diffview.nvim",
    },
    keys = {
      { "<leader>jl", "<cmd>J log<cr>", desc = "Jj log" },
      { "<leader>js", "<cmd>J status<cr>", desc = "Jj status" },
      { "<leader>jd", "<cmd>Jdiff<cr>", desc = "Jj diff" },
      { "<leader>jn", "<cmd>J new<cr>", desc = "Jj new" },
      { "<leader>jp", "<cmd>J push<cr>", desc = "Jj push" },
      { "<leader>jf", "<cmd>J fetch<cr>", desc = "Jj fetch" },
    },
    cmd = { "J", "Jdiff", "Jhdiff", "Jbrowse" },
    opts = {
      diff = { backend = "diffview" },
    },
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  },

  {
    "julienvincent/hunk.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = { "DiffEditor" },
    opts = {},
  },

  {
    "algmyr/vcsigns.nvim",
    dependencies = { "algmyr/vclib.nvim" },
    cond = is_pure_jj,
    event = "BufReadPre",
    opts = {
      signs = {
        text = {
          add = "▏",
          change = "▏",
          delete_below = "▁",
          delete_above = "▔",
        },
      },
      diff_opts = { algorithm = "histogram" },
    },
    keys = {
      {
        "[c",
        function()
          require("vcsigns.actions").hunk_prev(0, vim.v.count1)
        end,
        desc = "Previous hunk (vcs)",
      },
      {
        "]c",
        function()
          require("vcsigns.actions").hunk_next(0, vim.v.count1)
        end,
        desc = "Next hunk (vcs)",
      },
      {
        "<leader>hu",
        function()
          require("vcsigns.actions").hunk_undo(0)
        end,
        desc = "Undo hunk (vcs)",
      },
      {
        "<leader>hd",
        function()
          require("vcsigns.actions").toggle_hunk_diff(0)
        end,
        desc = "Inline hunk diff (vcs)",
      },
    },
  },
}
