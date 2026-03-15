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

      local mr = require("mason-registry")
      for _, pkg_name in ipairs({
        "java-debug-adapter",
        "java-test",
        "lemminx",
        "google-java-format",
        "vscode-spring-boot-tools",
      }) do
        local ok, pkg = pcall(mr.get_package, pkg_name)
        if ok and not pkg:is_installed() then
          pkg:install()
        end
      end

      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = { telemetry = { enable = false } },
        },
      })

      require("mason-lspconfig").setup({
        automatic_enable = {
          exclude = { "jdtls" },
        },
      })

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
          vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local m = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
          end
          m("gy", vim.lsp.buf.type_definition, "Type definition")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
          m("<leader>cr", vim.lsp.buf.rename, "Rename")
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
