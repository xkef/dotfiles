-- Runs .hurl files in place. `:HurlSetVariable server http://localhost:8080`
-- supplies what a project's e2e task passes on the command line.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "hurl" } },
  },

  {
    "jellydn/hurl.nvim",
    ft = "hurl",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    opts = { mode = "split", env_file = { "vars.env" } },
    keys = {
      { "<leader>hr", "<Cmd>HurlRunnerAt<CR>", ft = "hurl", desc = "Hurl: run entry at cursor" },
      { "<leader>hf", "<Cmd>HurlRunner<CR>", ft = "hurl", desc = "Hurl: run file" },
    },
  },
}
