-- basedpyright defaults to its "recommended" ruleset, which reports every Any
-- that crosses a boundary. Projects here type-check with mypy in CI, so the
-- editor's job is to catch what mypy would, not to argue about untyped
-- third-party stubs. "standard" matches that; a project wanting more can set
-- typeCheckingMode in its own pyproject.toml, which wins over this.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
              },
            },
          },
        },
      },
    },
  },
}
