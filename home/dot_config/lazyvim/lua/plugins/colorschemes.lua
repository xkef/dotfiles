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
    lazy = true,
    opts = {
      show_end_of_buffer = false,
      dim_inactive = { enabled = true, shade = "dark", percentage = 0.15 },
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        keywords = {},
        functions = {},
        variables = {},
      },
      lsp_styles = {
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
        inlay_hints = { background = true },
      },
      integrations = {
        blink_cmp = true,
        flash = true,
        gitsigns = true,
        lsp_trouble = true,
        mason = true,
        native_lsp = { enabled = true },
        neotree = true,
        snacks = true,
        treesitter = true,
        which_key = true,
      },
    },
  },

  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
      dim_inactive = true,
      lualine_bold = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
    },
  },

  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      dim_inactive_windows = true,
      styles = {
        bold = true,
        italic = true,
        transparency = false,
      },
    },
  },

  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      undercurl = true,
      commentStyle = { italic = true },
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      dimInactive = true,
      background = { dark = "wave", light = "lotus" },
    },
  },

  {
    "neanias/everforest-nvim",
    version = false,
    lazy = true,
    opts = {
      italics = true,
      disable_italic_comments = false,
      background = "medium",
    },
  },
}
