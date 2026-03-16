return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = "auto",
      background = { light = "latte", dark = "mocha" },
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
      style = "moon",
      light_style = "day",
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
      variant = "auto",
      dark_variant = "main",
      dim_inactive_windows = true,
      styles = {
        bold = true,
        italic = true,
        transparency = false,
      },
    },
  },

  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = {
      undercurl = true,
      underline = true,
      bold = true,
      italic = {
        strings = true,
        emphasis = true,
        comments = true,
        operators = false,
        folds = true,
      },
      strikethrough = true,
      contrast = "hard",
      dim_inactive = true,
    },
  },

  { "shaunsingh/nord.nvim", lazy = true },

  {
    "olimorris/onedarkpro.nvim",
    lazy = true,
    opts = {
      styles = {
        comments = "italic",
        keywords = "italic",
        functions = "bold",
        virtual_text = "italic",
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
    lazy = true,
    config = function()
      require("everforest").setup({
        background = "hard",
        italics = true,
        ui_contrast = "high",
        dim_inactive_windows = true,
        diagnostic_text_highlight = true,
        diagnostic_virtual_text = "coloured",
        diagnostic_line_highlight = true,
        float_style = "bright",
        inlay_hints_background = "dimmed",
        show_eob = false,
      })
    end,
  },

  {
    "Mofiqul/dracula.nvim",
    lazy = true,
    opts = {
      italic_comment = true,
      show_end_of_buffer = false,
    },
  },
}
