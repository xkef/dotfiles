-- OpenAPI specs: lua/openapi.lua follows $ref for gd and gr, next to
-- yamlls and jsonls. Redocly lints a spec root in a project with a
-- redocly.yaml, by the project's rules. redocly comes from the project's
-- node_modules or its mise.toml.
local openapi = require("openapi")
local project = require("project")

local REDOCLY_CONFIGS = { "redocly.yaml", ".redocly.yaml" }

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        openapi = {
          mason = false,
          cmd = openapi.cmd,
          filetypes = { "yaml", "json" },
          root_markers = { ".git" },
        },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      for _, ft in ipairs({ "yaml", "json" }) do
        opts.linters_by_ft[ft] = vim.list_extend(opts.linters_by_ft[ft] or {}, { "redocly" })
      end

      local parse = require("lint.linters.redocly").parser
      opts.linters = opts.linters or {}
      opts.linters.redocly = {
        cmd = function()
          local _, dir = project.config(vim.api.nvim_buf_get_name(0), REDOCLY_CONFIGS)
          local bin = dir and vim.fs.joinpath(dir, "node_modules/.bin/redocly")
          return bin and vim.fn.executable(bin) == 1 and bin or "redocly"
        end,
        condition = function(ctx)
          return project.config(ctx.filename, REDOCLY_CONFIGS) ~= nil and openapi.is_spec(0)
        end,
        args = {
          "lint",
          "--format",
          "codeclimate",
          "--config",
          function()
            return (project.config(vim.api.nvim_buf_get_name(0), REDOCLY_CONFIGS))
          end,
        },

        -- redocly also reports problems in the files a spec references.
        -- nvim-lint would place them in the spec's buffer, so drop them.
        parser = function(output, bufnr, cwd)
          local file = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
          local ok, decoded = pcall(vim.json.decode, output)
          local own = vim.tbl_filter(function(msg)
            local path = msg.location.path
            path = path:sub(1, 1) == "/" and path or vim.fs.joinpath(cwd, path)
            return vim.fs.normalize(path) == file
          end, ok and decoded or {})
          return parse(vim.json.encode(own), bufnr, cwd)
        end,
      }
    end,
  },
}
