return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      integrations = {
        blink_cmp = true,
        diffview = true,
        flash = true,
        gitsigns = true,
        grug_far = true,
        lsp_trouble = true,
        mason = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
  },
  { "folke/tokyonight.nvim", lazy = true },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = { variant = "auto" },
  },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "shaunsingh/nord.nvim", lazy = true },
  { "olimorris/onedarkpro.nvim", lazy = true },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      background = {
        dark = "wave",
        light = "lotus",
      },
    },
  },
  {
    "neanias/everforest-nvim",
    lazy = true,
    opts = {
      background = "hard",
    },
  },
  { "Mofiqul/dracula.nvim", lazy = true },
}
