vim.loader.enable()

-- Leader key (must be set before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.autowriteall = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.smartindent = true
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevelstart = 99
vim.opt.foldtext = ""
vim.opt.list = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
  extends = "»",
  precedes = "«",
  lead = "·",
}

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

-- Keymaps (wincent-style, see github.com/wincent/wincent)
local map = vim.keymap.set

-- Leader mappings
map("n", "<leader><leader>", "<C-^>", { desc = "Alternate file" })
map("n", "<leader>o", "<cmd>only<cr>", { desc = "Close other windows" })
map("n", "<leader>p", function()
  print(vim.fn.expand("%:p"))
end, { desc = "Show file path" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
map("n", "<leader>x", "<cmd>xit<cr>", { desc = "Write and quit" })
map("n", "<leader>v", "gv", { desc = "Reselect last visual" })
map("n", "<leader>zz", function()
  local pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd([[%s/\s\+$//e]])
  vim.api.nvim_win_set_cursor(0, pos)
end, { desc = "Strip trailing whitespace" })

-- Normal mode
map("n", "Q", "<nop>")
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Smart j/k: store jumps > 5 in jumplist
map("n", "j", function()
  return vim.v.count > 5 and "m'" .. vim.v.count .. "j" or "j"
end, { expr = true })
map("n", "k", function()
  return vim.v.count > 5 and "m'" .. vim.v.count .. "k" or "k"
end, { expr = true })

-- Quickfix navigation (arrow keys)
map("n", "<Up>", "<cmd>cprevious<cr>", { desc = "Previous quickfix" })
map("n", "<Down>", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "<Left>", "<cmd>cpfile<cr>", { desc = "Previous quickfix file" })
map("n", "<Right>", "<cmd>cnfile<cr>", { desc = "Next quickfix file" })

-- Visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("x", "<leader>p", '"_dP', { desc = "Paste without losing register" })

-- Command mode
map("c", "<C-a>", "<Home>")
map("c", "<C-e>", "<End>")

-- Diagnostics
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostic list" })

-- Autosave on focus loss and idle
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "CursorHold", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("Autosave", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].modified and vim.bo[ev.buf].buftype == "" and vim.fn.expand("%") ~= "" then
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent! write")
      end)
    end
  end,
})

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

require("lazy").setup("plugins", {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrwPlugin",
      },
    },
  },
})

-- Diagnostics: virtual line below current line avoids clashing with gitsigns blame
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Theme: read from ~/.config/theme/current, auto-reload on focus
require("theme").setup()
