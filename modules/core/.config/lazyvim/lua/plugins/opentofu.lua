-- OpenTofu in place of LazyVim's Terraform extra, which runs the terraform
-- binary. tofu comes from the project's mise.toml. Neovim knows no .tofu
-- filetype, and tofu_ls leaves out terraform-vars, so both are added here.
vim.filetype.add({ extension = { tofu = "terraform" } })

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "terraform", "hcl" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tofu_ls = { filetypes = { "opentofu", "opentofu-vars", "terraform", "terraform-vars" } },
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
