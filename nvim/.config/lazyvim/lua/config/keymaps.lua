local map = vim.keymap.set

-- Cowboy mode: warn on 10+ repeated hjkl without count (via folke/dot).
-- Smart jump counting: j/k >5 lines with count added to jumplist (via wincent).
vim.g.cowboy_mode = true

for _, key in ipairs({ "h", "j", "k", "l" }) do
  local count = 0
  local timer = assert(vim.uv.new_timer())
  map("n", key, function()
    if vim.g.cowboy_mode and vim.v.count == 0 then
      if count >= 10 then
        vim.notify("Hold it, cowboy!", vim.log.levels.WARN, { title = "Cowboy Mode" })
      else
        count = count + 1
        timer:start(2000, 0, function()
          count = 0
        end)
      end
    else
      count = 0
    end
    if (key == "j" or key == "k") and vim.v.count > 5 then
      return "m'" .. vim.v.count .. key
    end
    return key
  end, { expr = true })
end

map("n", "<leader>uC", function()
  vim.g.cowboy_mode = not vim.g.cowboy_mode
  vim.notify("Cowboy mode: " .. (vim.g.cowboy_mode and "on" or "off"), vim.log.levels.INFO)
end, { desc = "Toggle cowboy mode" })

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
