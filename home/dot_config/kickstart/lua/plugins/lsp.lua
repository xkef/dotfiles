local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason.nvim"),
  gh("mason-org/mason-lspconfig.nvim"),
  gh("folke/lazydev.nvim"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  gh("stevearc/conform.nvim"),
})

-- Adds vim.* types when editing the neovim config.
require("lazydev").setup({})
require("mason").setup({})

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
})

-- Autocompletion
require("blink.cmp").setup({
  sources = { default = { "lsp", "path", "buffer" } },
  signature = { enabled = true },
})

-- Formatting on save
require("conform").setup({
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
  formatters_by_ft = {
    lua = { "stylua" },
  },
})
vim.keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
