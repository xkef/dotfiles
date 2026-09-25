return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- LazyVim applies these after LSP loads, so vim.diagnostic.config in
      -- options.lua would be overwritten.
      diagnostics = {
        virtual_text = { current_line = true, priority = 10000 },
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
  -- Types for the WezTerm config's `wezterm` module.
  {
    "folke/lazydev.nvim",
    dependencies = { "DrKJeff16/wezterm-types" },
    opts = function(_, opts)
      opts.library = opts.library or {}
      table.insert(opts.library, { path = "wezterm-types", mods = { "wezterm" } })
    end,
  },
}
