return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        mason = true,
        native_lsp = { enabled = true },
        treesitter = true,
        lualine = true,
      },
    },
  },
  { "folke/tokyonight.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "shaunsingh/nord.nvim", lazy = true },
  { "olimorris/onedarkpro.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "neanias/everforest-nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
}
