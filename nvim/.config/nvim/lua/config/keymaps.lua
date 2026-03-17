local map = vim.keymap.set

-- Jump to config files via snacks picker (shows up under <leader>f in which-key)
map("n", "<leader>fc", function()
  require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find config file" })

map("n", "<leader>fC", function()
  local dotfiles = vim.env.DOTFILES_DIR or (vim.fn.expand("~") .. "/dotfiles")
  require("snacks").picker.files({ cwd = dotfiles })
end, { desc = "Find dotfiles" })
