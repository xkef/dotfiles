return {
  -- LSP: language server protocol support
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Mason: portable LSP/formatter/linter installer
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      -- Lua LSP config for editing neovim config (adds vim.* types)
      { "folke/lazydev.nvim", ft = "lua", opts = {} },
    },
    config = function()
      -- Keymaps activated when an LSP attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "Go to references")
          map("gI", vim.lsp.buf.implementation, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
        end,
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
        automatic_enable = true,
      })
    end,
  },

  -- Autocompletion
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      sources = { default = { "lsp", "path", "buffer" } },
      signature = { enabled = true },
    },
  },

  -- Formatting on save
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
}
