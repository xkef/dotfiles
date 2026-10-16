return {
  {
    "nicolasgb/jj.nvim",
    version = "*",
    dependencies = {
      "folke/snacks.nvim",
      "sindrets/diffview.nvim",
    },
    keys = {
      { "<leader>jl", "<cmd>J log<cr>", desc = "jj log" },
      { "<leader>js", "<cmd>J status<cr>", desc = "jj status" },
      { "<leader>jd", "<cmd>Jdiff<cr>", desc = "jj diff" },
      { "<leader>jn", "<cmd>J new<cr>", desc = "jj new" },
      { "<leader>jp", "<cmd>J push<cr>", desc = "jj push" },
      { "<leader>jf", "<cmd>J fetch<cr>", desc = "jj fetch" },
    },
    cmd = { "J", "Jdiff", "Jhdiff", "Jbrowse" },
    opts = {
      diff = { backend = "diffview" },
    },
  },

  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, { "<leader>j", group = "jj", icon = { cat = "filetype", name = "git" } })
    end,
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
}
