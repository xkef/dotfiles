-- buf's built-in language server. Mason installs buf, and its bin dir comes
-- first on PATH.
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
