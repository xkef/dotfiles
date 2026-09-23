-- Copy mode for zellij. EditScrollback opens the pane's scrollback in nvim
-- with this file as its only config, at the line the pane showed at the
-- bottom.
-- Motions, search, and v, V, and C-v work as in vim. y copies the selection
-- to the system clipboard and closes, like tmux's copy-selection-and-cancel.
-- Without pbcopy or wl-copy, nvim falls back to OSC 52, which zellij passes
-- through to the terminal.

vim.opt.modifiable = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"
vim.opt.swapfile = false
-- The status line would show the temp file's path. The ruler keeps the
-- position.
vim.opt.laststatus = 0

local function close()
  vim.cmd("qa!")
end

-- Align the view with the pane: the line zellij passes goes to the bottom.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("normal! zb")
  end,
})

vim.keymap.set("n", "q", close)
vim.keymap.set("n", "<Esc>", close)
vim.keymap.set("x", "y", function()
  vim.cmd('normal! "+y')
  close()
end)
vim.keymap.set("n", "Y", function()
  vim.cmd('normal! "+y$')
  close()
end)
