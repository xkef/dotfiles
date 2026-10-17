-- actionlint checks GitHub Actions workflows as CI does. It comes from the
-- project's mise.toml.
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.yaml = vim.list_extend(opts.linters_by_ft.yaml or {}, { "actionlint" })

      opts.linters = opts.linters or {}
      opts.linters.actionlint = {
        condition = function(ctx)
          return ctx.filename:find("/%.github/workflows/") ~= nil
        end,
      }
    end,
  },
}
