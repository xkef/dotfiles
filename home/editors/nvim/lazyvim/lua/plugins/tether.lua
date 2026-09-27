-- tether.nvim: review, follow, and coordinate the CLI agents working in this
-- repository. The build step links the helpers the agents call: agent-trail
-- and tether-run on PATH, and the pi extension.
local links = {
  ["bin/agent-trail"] = "~/.local/bin/agent-trail",
  ["bin/tether-run"] = "~/.local/bin/tether-run",
  ["extras/pi/agent-trail.ts"] = "~/.pi/agent/extensions/agent-trail.ts",
}

return {
  {
    "xkef/tether.nvim",
    event = "VeryLazy",
    cmd = "Tether",
    opts = {},
    build = function(plugin)
      for src, dst in pairs(links) do
        dst = vim.fn.expand(dst)
        vim.fn.mkdir(vim.fs.dirname(dst), "p")
        os.remove(dst)
        assert(vim.uv.fs_symlink(plugin.dir .. "/" .. src, dst))
      end
    end,
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
