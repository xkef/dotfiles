vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- The python extra reads this when lazy.setup() imports its spec, so it must
-- come first. LazyVim defaults to pyright. basedpyright is the maintained fork
-- and reports the stricter diagnostics these projects type for.
vim.g.lazyvim_python_lsp = "basedpyright"

-- Debug helpers from folke/dot: dd(value) inspects, bt() prints a backtrace.
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
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.dap.core" },
    { import = "lazyvim.plugins.extras.test.core" },
    { import = "lazyvim.plugins.extras.editor.harpoon2" },
    { import = "lazyvim.plugins.extras.editor.illuminate" },
    { import = "plugins" },
  },
})

-- lua/config/autocmds.lua registers the theme reload. LazyVim applies the
-- initial colorscheme above.
