-- basedpyright defaults to its "recommended" ruleset, which reports every Any
-- that crosses a boundary. Projects here type-check with mypy in CI, so the
-- editor should catch what mypy would and stay quiet about untyped
-- third-party stubs. "standard" matches that. A project that wants more can
-- set typeCheckingMode in its own pyproject.toml, which wins over this.
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
