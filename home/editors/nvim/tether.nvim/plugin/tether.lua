if vim.g.loaded_tether then
  return
end
vim.g.loaded_tether = true

vim.api.nvim_create_user_command("Tether", function(cmd)
  require("tether").ensure()
  require("tether").command(cmd)
end, {
  nargs = "*",
  range = true,
  desc = "tether: cockpit, review, follow, pick, send, undo, checkpoint, comment, hunks",
  complete = function(arglead, cmdline)
    return require("tether").completion(arglead, cmdline)
  end,
})
