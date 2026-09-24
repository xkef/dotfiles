return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- LazyVim applies these after LSP loads, so vim.diagnostic.config in
      -- options.lua would be overwritten.
      diagnostics = {
        virtual_text = { current_line = true, priority = 10000 },
        virtual_lines = false,
      },
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
