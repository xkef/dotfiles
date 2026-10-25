-- Colorschemes, all lazy-loaded. require("theme").apply() loads the one
-- that `theme` applied, by name.
return {

  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      dim_inactive = { enabled = true },
    },
  },

  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      dim_inactive = true,
      lualine_bold = true,
    },
  },

  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      dim_inactive_windows = true,
    },
  },

  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      dimInactive = true,
    },
  },
}
