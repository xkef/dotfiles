-- Kickstart-style neovim config — minimal, self-bootstrapping.
-- Run as: NVIM_APPNAME=kickstart nvim (or just `knvim`)
-- See: https://github.com/nvim-lua/kickstart.nvim

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Bootstrap lazy.nvim
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
  { import = "plugins" },
}, {
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true, notify = false },
})

-- Apply theme from ~/.config/theme/current and auto-reload on focus
require("theme").apply()
require("theme").setup()
