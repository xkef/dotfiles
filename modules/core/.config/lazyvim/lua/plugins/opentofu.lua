-- OpenTofu in place of LazyVim's Terraform extra, which runs the terraform
-- binary. tofu comes from the project's mise.toml.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "terraform", "hcl" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tofu_ls = {},
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        terraform = { "tofu_fmt" },
        ["terraform-vars"] = { "tofu_fmt" },
      },
    },
  },
}
