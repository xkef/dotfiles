return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        globalstatus = true,
        component_separators = "",
        section_separators = "",
        disabled_filetypes = { statusline = { "lazy" } },
      },
      sections = {
        lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
        lualine_b = { { "branch", icon = "" } },
        lualine_c = {
          { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
          { "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
        },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1, symbols = { modified = " ●", readonly = " " } } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    },
  },
}
