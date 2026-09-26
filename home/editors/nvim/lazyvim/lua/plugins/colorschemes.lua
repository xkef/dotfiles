-- Colorschemes, all lazy-loaded. require("theme").apply() maps the current
-- tinty scheme to one of these, and renders any other scheme through
-- tinted-nvim.
return {
  {
    "tinted-theming/tinted-nvim",
    lazy = true,
    opts = { apply_scheme_on_startup = false },
  },

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

  {
    "neanias/everforest-nvim",
    version = false,
    lazy = true,
    opts = {
      italics = true,
    },
  },
}
