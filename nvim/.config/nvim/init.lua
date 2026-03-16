vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = function()
          require("theme").apply()
        end,
      },
    },
    { import = "lazyvim.plugins.extras.lang.java" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "lazyvim.plugins.extras.editor.harpoon2" },
    { import = "plugins" },
  },
})

-- OSC 52 clipboard (works over SSH, in tmux, everywhere)
if vim.env.SSH_TTY or vim.env.TMUX then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
  extends = "»",
  precedes = "«",
  lead = "·",
}

-- Diagnostics: inline virtual text on current line only
vim.diagnostic.config({
  virtual_text = { current_line = true, priority = 10000 },
  virtual_lines = false,
})

-- Theme: read from ~/.config/theme/current, auto-reload on focus
require("theme").setup()
