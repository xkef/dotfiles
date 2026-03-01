-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- LazyVim marker (used by install script to detect existing config)
local marker = vim.fn.stdpath("config") .. "/.lazyvim"
if not vim.loop.fs_stat(marker) then
  local f = io.open(marker, "w")
  if f then f:close() end
end

-- Leader key (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Import LazyVim and custom plugins
require("lazy").setup({
  spec = {
    -- LazyVim core
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = "catppuccin",
      },
    },

    -- LazyVim extras (language support, tools)
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.java" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.terraform" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.clangd" },

    -- Coding extras
    { import = "lazyvim.plugins.extras.ai.copilot" },
    { import = "lazyvim.plugins.extras.coding.yanky" },

    -- Editor extras
    { import = "lazyvim.plugins.extras.editor.dial" },
    { import = "lazyvim.plugins.extras.editor.illuminate" },

    -- Formatting & Linting
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    { import = "lazyvim.plugins.extras.linting.eslint" },

    -- DAP (debugging)
    { import = "lazyvim.plugins.extras.dap.core" },

    -- UI extras
    { import = "lazyvim.plugins.extras.ui.mini-animate" },

    -- Custom plugins
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
