-- tinted-nvim renders the Base16 or Base24 scheme that `theme` (tinty)
-- applied. It watches tinty's current_scheme file and recolors running
-- instances on a switch. LazyVim's bundled colorschemes stay disabled.
return {
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  {
    "tinted-theming/tinted-nvim",
    lazy = false,
    priority = 1000,
    opts = {
      default_scheme = "base16-catppuccin-mocha",
      selector = { enabled = true, mode = "file", watch = true },
    },
  },
}
