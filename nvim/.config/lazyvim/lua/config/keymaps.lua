local map = vim.keymap.set

-- Jump to config files via snacks picker (shows up under <leader>f in which-key)
map("n", "<leader>fc", function()
  require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find config file" })

map("n", "<leader>fC", function()
  local dotfiles = vim.env.DOTFILES_DIR or (vim.fn.expand("~") .. "/dotfiles")
  require("snacks").picker.files({ cwd = dotfiles })
end, { desc = "Find dotfiles" })

map("n", "<leader>uD", function()
  local cfg = vim.diagnostic.config()
  local vt = cfg.virtual_text
  if type(vt) == "table" and vt.current_line then
    vim.diagnostic.config({ virtual_text = true })
  else
    vim.diagnostic.config({ virtual_text = { current_line = true, priority = 10000 } })
  end
end, { desc = "Toggle diagnostics virtual text (all/current line)" })

map("n", "<leader>gd", function()
  require("gitsigns").diffthis()
end, { desc = "Diff this" })

map("n", "<leader>gD", function()
  require("gitsigns").diffthis("~")
end, { desc = "Diff this ~" })
