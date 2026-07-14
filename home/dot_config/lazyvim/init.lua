vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Global debug helpers backed by snacks.debug (via folke/dot).
-- Usage: dd(some_table), bt() for backtrace.
_G.dd = function(...)
  Snacks.debug.inspect(...)
end
_G.bt = function()
  Snacks.debug.backtrace()
end
vim.print = _G.dd

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

local function apply_theme()
  local ok, theme = pcall(require, "theme")
  if ok and type(theme.apply) == "function" then
    theme.apply()
  else
    pcall(vim.cmd.colorscheme, "habamax")
  end
end

require("lazy").setup({
  spec = {
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = apply_theme,
      },
    },
    { import = "lazyvim.plugins.extras.lang.java" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.docker" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "lazyvim.plugins.extras.editor.harpoon2" },
    { import = "lazyvim.plugins.extras.editor.illuminate" },
    { import = "plugins" },
  },
})

-- Theme auto-reload is registered in lua/config/autocmds.lua when the theme
-- package is installed. Initial colorscheme is applied above via LazyVim.
