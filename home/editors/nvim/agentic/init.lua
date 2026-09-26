-- Neovim for working next to CLI agents: tether.nvim on a small vim.pack
-- base, no distro. Run it with `anvim` or NVIM_APPNAME=agentic nvim.
-- `:lua vim.pack.update()` updates plugins and nvim-pack-lock.json.
--
-- Keys follow LazyVim, so the same fingers work in both configs:
-- <leader><space> files, <leader>/ grep, <leader>e explorer, - oil, and
-- <leader>a for the agent (cockpit, review, follow, pick, send, undo).

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.undofile = true
opt.updatetime = 250
opt.wrap = true
opt.list = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣", extends = "»", precedes = "«", lead = "·" }
opt.inccommand = "split"
opt.laststatus = 3
-- Agents write files under open buffers all the time.
opt.autoread = true
if vim.env.SSH_TTY then
  vim.g.clipboard = "osc52"
end
opt.clipboard = "unnamedplus"

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("agentic.checktime", { clear = true }),
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("silent! checktime")
    end
  end,
})

-- Build steps after vim.pack installs or updates a plugin. The autocmd must
-- exist before the first vim.pack.add() call.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local kind, name = ev.data.kind, ev.data.spec.name
    if (kind == "install" or kind == "update") and name == "nvim-treesitter" then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    end
  end,
})

local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  gh("folke/snacks.nvim"),
  gh("folke/which-key.nvim"),
  gh("stevearc/oil.nvim"),
  gh("mrjones2014/smart-splits.nvim"),
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("tinted-theming/tinted-nvim"),
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  gh("neovim/nvim-lspconfig"),
  gh("mason-org/mason.nvim"),
  gh("mason-org/mason-lspconfig.nvim"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
})

-- tether.nvim lives in the dotfiles and Dotter links it here. TETHER_DIR
-- points at a checkout instead, for plugin development.
local tether_dir = vim.env.TETHER_DIR or vim.fn.expand("~/.local/share/tether.nvim")
if vim.uv.fs_stat(tether_dir) then
  opt.rtp:prepend(tether_dir)
  require("tether").setup({})
end

-- Theme: follows tinty like the LazyVim config, through the same module.
local ok_theme, theme = pcall(require, "theme")
if ok_theme then
  pcall(require("tinted-nvim").setup, { apply_scheme_on_startup = false })
  theme.apply()
  theme.setup()
else
  vim.cmd.colorscheme("catppuccin-frappe")
end

local Snacks = require("snacks")
Snacks.setup({
  picker = {
    enabled = true,
    sources = {
      files = { hidden = true },
      grep = { hidden = true },
      explorer = { hidden = true },
    },
  },
  explorer = { enabled = true, replace_netrw = false },
  notifier = { enabled = true },
  input = { enabled = true },
  indent = { enabled = true },
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  words = { enabled = true },
})

require("oil").setup({
  default_file_explorer = true,
  view_options = {
    show_hidden = true,
    is_always_hidden = function(name)
      return name == ".." or name == ".git" or name == ".jj" or name == ".DS_Store"
    end,
  },
})

require("which-key").setup({
  spec = {
    { "<leader>a", group = "agent" },
    { "<leader>f", group = "file" },
    { "<leader>s", group = "search" },
    { "<leader>c", group = "code" },
  },
})

local map = vim.keymap.set
local pick = Snacks.picker

-- Find and navigate, as in LazyVim.
map("n", "<leader><space>", function()
  pick.files()
end, { desc = "Find files" })
map("n", "<leader>/", function()
  pick.grep()
end, { desc = "Grep" })
map("n", "<leader>,", function()
  pick.buffers()
end, { desc = "Buffers" })
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorer" })
map("n", "<leader>ff", function()
  pick.files()
end, { desc = "Find files" })
map("n", "<leader>fr", function()
  pick.recent()
end, { desc = "Recent files" })
map("n", "<leader>sg", function()
  pick.grep()
end, { desc = "Grep" })
map({ "n", "x" }, "<leader>sw", function()
  pick.grep_word()
end, { desc = "Grep word or selection" })
map("n", "<leader>ss", function()
  pick.lsp_symbols()
end, { desc = "Symbols" })
map("n", "<leader>sd", function()
  pick.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>sk", function()
  pick.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sr", function()
  pick.resume()
end, { desc = "Resume picker" })
map("n", "-", "<Cmd>Oil<CR>", { desc = "Open parent directory" })
map("n", "<leader>fC", function()
  pick.files({ cwd = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles") })
end, { desc = "Find dotfiles" })

-- C-hjkl moves across WezTerm panes and Neovim splits alike, so the agent
-- pane is one key away.
local smart_splits = require("smart-splits")
for key, fn in pairs({
  ["<C-h>"] = "move_cursor_left",
  ["<C-j>"] = "move_cursor_down",
  ["<C-k>"] = "move_cursor_up",
  ["<C-l>"] = "move_cursor_right",
  ["<A-h>"] = "resize_left",
  ["<A-j>"] = "resize_down",
  ["<A-k>"] = "resize_up",
  ["<A-l>"] = "resize_right",
}) do
  map("n", key, smart_splits[fn])
end

-- Treesitter: the main branch only installs parsers. This starts
-- highlighting per buffer and installs a missing parser on first use.
local treesitter = require("nvim-treesitter")
local available = treesitter.get_available()
local function ts_attach(buf, lang)
  if vim.treesitter.language.add(lang) and vim.api.nvim_buf_is_valid(buf) then
    vim.treesitter.start(buf, lang)
    if vim.treesitter.query.get(lang, "indents") then
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end
end
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then
      return
    end
    if vim.tbl_contains(treesitter.get_installed("parsers"), lang) or not vim.tbl_contains(available, lang) then
      ts_attach(args.buf, lang)
      return
    end
    treesitter.install(lang):await(function()
      ts_attach(args.buf, lang)
    end)
  end,
})

-- LSP and completion.
require("mason").setup({})
require("mason-lspconfig").setup({ ensure_installed = { "lua_ls" } })
require("blink.cmp").setup({
  sources = { default = { "lsp", "path", "buffer" } },
  signature = { enabled = true },
})
vim.diagnostic.config({ virtual_text = { current_line = true }, severity_sort = true })
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local function lsp(keys, fn, desc)
      map("n", keys, fn, { buffer = event.buf, desc = desc })
    end
    lsp("gd", function()
      pick.lsp_definitions()
    end, "Go to definition")
    lsp("gr", function()
      pick.lsp_references()
    end, "References")
    lsp("gI", function()
      pick.lsp_implementations()
    end, "Implementations")
    lsp("<leader>ca", vim.lsp.buf.code_action, "Code action")
    lsp("<leader>cr", vim.lsp.buf.rename, "Rename")
  end,
})

-- Statusline with the agent state from tether.
function _G.agentic_status()
  local ok, tether = pcall(require, "tether")
  local s = ok and tether.status() or ""
  return s ~= "" and (" 󰚩 " .. s .. " ") or ""
end
opt.statusline = " %f %m%r%h%=%{v:lua.agentic_status()} %l:%c "
