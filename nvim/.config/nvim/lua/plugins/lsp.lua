return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      require("mason").setup()

      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = { telemetry = { enable = false } },
        },
      })

      require("mason-lspconfig").setup({ automatic_enable = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local m = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
          end
          m("gd", vim.lsp.buf.definition, "Go to definition")
          m("gr", vim.lsp.buf.references, "References")
          m("gI", vim.lsp.buf.implementation, "Implementation")
          m("gy", vim.lsp.buf.type_definition, "Type definition")
          m("K", vim.lsp.buf.hover, "Hover")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
          m("<leader>cr", vim.lsp.buf.rename, "Rename")
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end,
      })
    end,
  },

  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      snippets = { preset = "luasnip" },
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          lsp = { score_offset = 90 },
          path = { score_offset = 80 },
          snippets = { score_offset = 70 },
          buffer = { score_offset = 50 },
        },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      signature = { enabled = true },
    },
  },
}
