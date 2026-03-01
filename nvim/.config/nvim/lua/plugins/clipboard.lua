-- OSC 52 clipboard support (works over SSH, in tmux, everywhere)
return {
  {
    "LazyVim/LazyVim",
    opts = function()
      -- Use OSC 52 for clipboard when no display server is available
      -- This works in Ghostty, Kitty, WezTerm, Alacritty, iTerm2
      -- and works over SSH and inside tmux
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
    end,
  },
}
