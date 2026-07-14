return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          capabilities = {
            workspace = {
              didChangeWatchedFiles = { dynamicRegistration = false },
            },
          },
        },
      },
    },
  },
}
