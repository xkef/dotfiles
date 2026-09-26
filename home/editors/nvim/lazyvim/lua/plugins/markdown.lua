-- Replaces the LazyVim markdown extra's markdownlint-cli2 with rumdl for
-- linting and dprint for formatting, and adds vale for prose. rumdl and
-- dprint resolve from PATH through the mise shims, which mise.toml pins per
-- project. vale comes from Homebrew and reads ~/.config/vale/.vale.ini.
return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = { "rumdl", "vale" }
      opts.linters_by_ft["markdown.mdx"] = { "rumdl", "vale" }
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
