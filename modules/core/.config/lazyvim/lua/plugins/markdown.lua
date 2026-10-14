-- Replaces the LazyVim markdown extra's markdownlint-cli2 with rumdl for
-- linting and dprint for formatting, and adds vale for prose. All three come
-- from Homebrew or pacman, and a project's mise.toml can pin its own
-- versions through the mise shims. rumdl and vale run only in a project
-- with its own config.

-- Both tools search for config from the working directory, not from the
-- file, so the linter passes the file's project config explicitly. The
-- search stops below $HOME so a user-level config such as
-- ~/.config/vale/.vale.ini never counts as a project config. The dotfiles
-- repo keeps its vale config at .config/vale/.vale.ini.
local VALE_CONFIGS = { ".vale.ini", "_vale.ini", ".config/vale/.vale.ini" }
local RUMDL_CONFIGS = {
  ".rumdl.toml",
  "rumdl.toml",
  ".config/rumdl.toml",
  ".markdownlint.json",
  ".markdownlint.jsonc",
  ".markdownlint.yaml",
  ".markdownlint.yml",
  ".markdownlint-cli2.jsonc",
  ".markdownlint-cli2.yaml",
}

local function project_config(file, names)
  for dir in vim.fs.parents(file) do
    if dir == vim.env.HOME then
      return nil
    end

    for _, name in ipairs(names) do
      local path = vim.fs.joinpath(dir, name)
      if vim.uv.fs_stat(path) then
        return path
      end
    end
  end
end

-- Linter overrides that skip files outside a configured project and point
-- the tool at the project config.
local function configured(names, args)
  return {
    condition = function(ctx)
      return project_config(ctx.filename, names) ~= nil
    end,
    prepend_args = vim.list_extend(args, {
      "--config",
      function()
        return project_config(vim.api.nvim_buf_get_name(0), names)
      end,
    }),
  }
end

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = { "rumdl", "vale" }
      opts.linters_by_ft["markdown.mdx"] = { "rumdl", "vale" }

      -- vale merges the global config into a project config unless told
      -- not to.
      opts.linters = opts.linters or {}
      opts.linters.rumdl = configured(RUMDL_CONFIGS, {})

      -- nvim-lint reads rumdl's JSON from stderr, but rumdl writes it to
      -- stdout, so no rumdl diagnostic ever appeared.
      opts.linters.rumdl.stream = "stdout"
      opts.linters.vale = configured(VALE_CONFIGS, { "--no-global" })
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
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },
}
