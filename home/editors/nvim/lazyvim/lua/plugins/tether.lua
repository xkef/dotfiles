-- tether.nvim: review, follow, and coordinate the CLI agents working in this
-- repository. Dotter links the plugin from home/editors/nvim/tether.nvim.
local dir = vim.fn.expand("~/.local/share/tether.nvim")

return {
  {
    dir = dir,
    name = "tether.nvim",
    cond = vim.uv.fs_stat(dir) ~= nil,
    event = "VeryLazy",
    cmd = "Tether",
    opts = {},
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "agent", icon = { icon = "󰚩", color = "purple" } },
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return require("tether").status()
        end,
        cond = function()
          return package.loaded["tether"] ~= nil
        end,
      })
    end,
  },
}
