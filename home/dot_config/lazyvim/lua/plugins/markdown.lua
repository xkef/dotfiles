-- Replace the LazyVim markdown extra's markdownlint-cli2 tooling with rumdl
-- (linter) and dprint (formatter). Both binaries resolve from PATH via the
-- mise shims, pinned per-project by mise.toml.
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = { "rumdl" }
      opts.linters_by_ft["markdown.mdx"] = { "rumdl" }
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.markdown = { "dprint" }
      opts.formatters_by_ft["markdown.mdx"] = { "dprint" }
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "markdownlint-cli2"
      end, opts.ensure_installed or {})
    end,
  },
}
