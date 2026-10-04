-- buf's built-in language server, which the mise shims resolve per project.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "proto" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        buf_ls = {},
      },
    },
  },
}
