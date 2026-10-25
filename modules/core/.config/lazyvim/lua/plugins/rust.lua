-- rust-analyzer runs from stable, whatever toolchain the project pins. A
-- pin without the rust-analyzer component still gets a language server.
return {
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        cmd = { "rustup", "run", "stable", "rust-analyzer" },
      },
    },
  },
}
