-- OSC 52 clipboard works over SSH.
if vim.env.SSH_TTY then
  vim.g.clipboard = "osc52"
end

vim.opt.wrap = true
vim.opt.listchars = {
  tab = "→ ",
  trail = "·",
  nbsp = "␣",
  extends = "»",
  precedes = "«",
  lead = "·",
}
