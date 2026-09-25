local function gh(repo)
  return "https://github.com/" .. repo
end

vim.pack.add({
  { src = gh("catppuccin/nvim"), name = "catppuccin" },
  gh("mrjones2014/smart-splits.nvim"),
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-telescope/telescope.nvim"),
  gh("nvim-telescope/telescope-fzf-native.nvim"),
  gh("nvim-telescope/telescope-ui-select.nvim"),
  gh("folke/which-key.nvim"),
  gh("lewis6991/gitsigns.nvim"),
  gh("nvim-mini/mini.nvim"),
})

-- The fallback nvim keeps a fixed theme. The LazyVim config follows the
-- tinty scheme.
vim.cmd.colorscheme("catppuccin-nvim")

-- C-hjkl moves across WezTerm panes and nvim splits alike.
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
  vim.keymap.set("n", key, smart_splits[fn])
end

-- Treesitter: the main branch of nvim-treesitter only installs parsers.
-- This autocmd starts highlighting and indentation per buffer, and installs
-- a missing parser on first use.
local treesitter = require("nvim-treesitter")
treesitter.install({ "lua", "vim", "vimdoc", "bash", "json", "yaml", "toml", "markdown" })
local available_parsers = treesitter.get_available()

local function treesitter_attach(buf, lang)
  if not vim.treesitter.language.add(lang) or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.treesitter.start(buf, lang)
  if vim.treesitter.query.get(lang, "indents") then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then
      return
    end

    local installed = vim.tbl_contains(treesitter.get_installed("parsers"), lang)
    if installed or not vim.tbl_contains(available_parsers, lang) then
      treesitter_attach(args.buf, lang)
      return
    end

    treesitter.install(lang):await(function()
      treesitter_attach(args.buf, lang)
    end)
  end,
})

local telescope = require("telescope")
telescope.setup({
  extensions = {
    ["ui-select"] = { require("telescope.themes").get_dropdown() },
  },
})
pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "ui-select")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Buffers" })

require("which-key").setup({})
require("gitsigns").setup({})

require("mini.ai").setup()
require("mini.surround").setup()
require("mini.statusline").setup()
require("mini.pairs").setup()
